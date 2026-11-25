SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ============================================================================
-- CelestialDatabase
-- A SQL Server database for cataloguing celestial bodies (stars, planets,
-- Messier objects, asteroids, moons, comets, deep-sky objects, etc.)
-- with equatorial coordinates (Right Ascension / Declination).
--
-- Apparent magnitude is stored in CelestialBody.Magnitude.
--   * Lower (more negative) = brighter. Sun ~ -26.7, Sirius ~ -1.46.
--   * "Magnitude +6 or greater" (fainter objects)  -> WHERE Magnitude >= 6.0
--   * "Magnitude 6 or brighter" (naked-eye limit) -> WHERE Magnitude <= 6.0
-- ============================================================================

IF DB_ID(N'CelestialDatabase') IS NULL
BEGIN
    CREATE DATABASE CelestialDatabase;
END
GO

USE CelestialDatabase;
GO

-- ----------------------------------------------------------------------------
-- Schemas / lookup tables
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.BodyType', N'U') IS NULL
CREATE TABLE dbo.BodyType (
    BodyTypeID   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TypeName     NVARCHAR(50)  NOT NULL UNIQUE,
    Description  NVARCHAR(255) NULL
);
GO

IF OBJECT_ID(N'dbo.Constellation', N'U') IS NULL
CREATE TABLE dbo.Constellation (
    ConstellationID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name           NVARCHAR(50) NOT NULL UNIQUE,
    Abbreviation   NVARCHAR(5)  NULL,
    Genitive       NVARCHAR(50) NULL
);
GO

-- ----------------------------------------------------------------------------
-- Core catalogue table
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.CelestialBody', N'U') IS NULL
CREATE TABLE dbo.CelestialBody (
    BodyID          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL,
    CommonName      NVARCHAR(100) NULL,
    BodyTypeID      INT           NOT NULL,
    Magnitude       DECIMAL(6,2)  NULL,          -- apparent visual magnitude
    RA_Hours        DECIMAL(10,6) NULL,          -- 0.000000 .. 23.999999
    DEC_Degrees     DECIMAL(9,6)  NULL,          -- -90.000000 .. +90.000000
    Distance_LY     DECIMAL(18,6) NULL,          -- distance in light-years
    ConstellationID INT           NULL,
    Description     NVARCHAR(MAX) NULL,
    DiscoveredBy    NVARCHAR(100) NULL,
    DiscoveryYear   INT           NULL,
    CreatedAt       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_CelestialBody_BodyType
        FOREIGN KEY (BodyTypeID) REFERENCES dbo.BodyType(BodyTypeID),
    CONSTRAINT FK_CelestialBody_Constellation
        FOREIGN KEY (ConstellationID) REFERENCES dbo.Constellation(ConstellationID),
    CONSTRAINT CK_CelestialBody_RA
        CHECK (RA_Hours IS NULL OR (RA_Hours >= 0 AND RA_Hours < 24)),
    CONSTRAINT CK_CelestialBody_DEC
        CHECK (DEC_Degrees IS NULL OR (DEC_Degrees >= -90 AND DEC_Degrees <= 90)),
    CONSTRAINT CK_CelestialBody_Magnitude
        CHECK (Magnitude IS NULL OR Magnitude BETWEEN -30 AND 30)
);
GO

-- Computed column: RA expressed in degrees (RA_hours * 15)
IF COL_LENGTH(N'dbo.CelestialBody', N'RA_Degrees') IS NULL
    ALTER TABLE dbo.CelestialBody ADD RA_Degrees AS (RA_Hours * 15.0) PERSISTED;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_CelestialBody_Magnitude' AND object_id=OBJECT_ID(N'dbo.CelestialBody'))
    CREATE INDEX IX_CelestialBody_Magnitude ON dbo.CelestialBody(Magnitude);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_CelestialBody_RA_DEC' AND object_id=OBJECT_ID(N'dbo.CelestialBody'))
    CREATE INDEX IX_CelestialBody_RA_DEC ON dbo.CelestialBody(RA_Hours, DEC_Degrees);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_CelestialBody_Type' AND object_id=OBJECT_ID(N'dbo.CelestialBody'))
    CREATE INDEX IX_CelestialBody_Type ON dbo.CelestialBody(BodyTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_CelestialBody_Name' AND object_id=OBJECT_ID(N'dbo.CelestialBody'))
    CREATE INDEX IX_CelestialBody_Name ON dbo.CelestialBody(Name);
GO

-- ----------------------------------------------------------------------------
-- Specialised (1:1) detail tables
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.Star', N'U') IS NULL
CREATE TABLE dbo.Star (
    BodyID           BIGINT NOT NULL PRIMARY KEY,
    SpectralType     NVARCHAR(10)   NULL,
    SurfaceTempK     INT            NULL,
    LuminositySolar  DECIMAL(18,6)  NULL,
    MassSolar        DECIMAL(18,6)  NULL,
    RadiusSolar      DECIMAL(18,6)  NULL,
    ParallaxMas      DECIMAL(12,6)  NULL,   -- milliarcseconds
    ProperMotionRA   DECIMAL(12,6)  NULL,   -- mas/yr
    ProperMotionDec  DECIMAL(12,6)  NULL,   -- mas/yr
    CONSTRAINT FK_Star_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Planet', N'U') IS NULL
CREATE TABLE dbo.Planet (
    BodyID            BIGINT NOT NULL PRIMARY KEY,
    PlanetClass       NVARCHAR(50)  NULL,   -- terrestrial, gas giant, ice giant, dwarf
    MassEarth         DECIMAL(18,6) NULL,
    RadiusEarth       DECIMAL(18,6) NULL,
    OrbitalPeriodDays DECIMAL(18,6) NULL,
    SemiMajorAxisAU   DECIMAL(18,6) NULL,
    Eccentricity      DECIMAL(10,8) NULL,
    InclinationDeg    DECIMAL(8,4)  NULL,
    RotationPeriodHrs DECIMAL(12,6) NULL,
    HasRings          BIT           NULL,
    Atmosphere        NVARCHAR(255) NULL,
    CONSTRAINT FK_Planet_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Moon', N'U') IS NULL
CREATE TABLE dbo.Moon (
    BodyID            BIGINT NOT NULL PRIMARY KEY,
    ParentBodyID      BIGINT NOT NULL,
    DiameterKm        DECIMAL(12,3) NULL,
    MassKg            DECIMAL(30,6) NULL,
    OrbitalPeriodDays DECIMAL(12,6) NULL,
    SemiMajorAxisKm   DECIMAL(18,3) NULL,
    CONSTRAINT FK_Moon_Body   FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE,
    CONSTRAINT FK_Moon_Parent FOREIGN KEY (ParentBodyID)
        REFERENCES dbo.CelestialBody(BodyID)
);
GO

IF OBJECT_ID(N'dbo.Asteroid', N'U') IS NULL
CREATE TABLE dbo.Asteroid (
    BodyID            BIGINT NOT NULL PRIMARY KEY,
    AsteroidClass     NVARCHAR(50)  NULL,   -- main-belt, NEO, Trojan, KBO, ...
    DiameterKm        DECIMAL(12,3) NULL,
    OrbitalPeriodDays DECIMAL(12,6) NULL,
    SemiMajorAxisAU   DECIMAL(12,6) NULL,
    Eccentricity      DECIMAL(10,8) NULL,
    InclinationDeg    DECIMAL(8,4)  NULL,
    Albedo            DECIMAL(6,4)  NULL,
    CONSTRAINT FK_Asteroid_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Comet', N'U') IS NULL
CREATE TABLE dbo.Comet (
    BodyID             BIGINT NOT NULL PRIMARY KEY,
    CometType          NVARCHAR(50)  NULL,   -- short-period, long-period, sungrazer
    OrbitalPeriodYears DECIMAL(12,6) NULL,
    PerihelionAU       DECIMAL(12,6) NULL,
    AphelionAU         DECIMAL(12,6) NULL,
    InclinationDeg     DECIMAL(8,4)  NULL,
    Eccentricity       DECIMAL(10,8) NULL,
    LastPerihelion     DATE          NULL,
    NextPerihelion     DATE          NULL,
    CONSTRAINT FK_Comet_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.MessierObject', N'U') IS NULL
CREATE TABLE dbo.MessierObject (
    BodyID              BIGINT NOT NULL PRIMARY KEY,
    MessierNumber       INT    NOT NULL UNIQUE,
    NGCNumber           INT    NULL,
    ObjectType          NVARCHAR(50)  NULL,   -- galaxy, nebula, cluster, supernova remnant
    Distance_KLY        DECIMAL(12,3) NULL,    -- thousands of light-years
    ApparentSizeArcmin  DECIMAL(8,2)  NULL,
    CONSTRAINT FK_Messier_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE,
    CONSTRAINT CK_Messier_Number CHECK (MessierNumber BETWEEN 1 AND 110)
);
GO

IF OBJECT_ID(N'dbo.DeepSkyObject', N'U') IS NULL
CREATE TABLE dbo.DeepSkyObject (
    BodyID             BIGINT NOT NULL PRIMARY KEY,
    Catalogue          NVARCHAR(20)  NULL,   -- NGC, IC, Caldwell, ...
    CatalogueNumber    NVARCHAR(20)  NULL,
    ObjectType         NVARCHAR(50)  NULL,
    Distance_KLY       DECIMAL(12,3) NULL,
    ApparentSizeArcmin DECIMAL(8,2)  NULL,
    CONSTRAINT FK_DSO_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

-- ----------------------------------------------------------------------------
-- Observation log (optional)
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.Observation', N'U') IS NULL
CREATE TABLE dbo.Observation (
    ObservationID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BodyID       BIGINT NOT NULL,
    ObservedAt   DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    Location     NVARCHAR(100) NULL,
    Seeing       NVARCHAR(50)  NULL,
    Instrument   NVARCHAR(100) NULL,
    Notes        NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Observation_Body FOREIGN KEY (BodyID)
        REFERENCES dbo.CelestialBody(BodyID) ON DELETE CASCADE
);
GO

-- ----------------------------------------------------------------------------
-- Helpful views
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.vw_CelestialBodySummary', N'V') IS NOT NULL
    DROP VIEW dbo.vw_CelestialBodySummary;
GO
CREATE VIEW dbo.vw_CelestialBodySummary AS
SELECT
    cb.BodyID,
    cb.Name,
    cb.CommonName,
    bt.TypeName        AS BodyType,
    cb.Magnitude,
    cb.RA_Hours,
    cb.RA_Degrees,
    cb.DEC_Degrees,
    cb.Distance_LY,
    c.Name             AS Constellation,
    c.Abbreviation     AS ConstellationAbbr
FROM dbo.CelestialBody cb
JOIN dbo.BodyType bt ON bt.BodyTypeID = cb.BodyTypeID
LEFT JOIN dbo.Constellation c ON c.ConstellationID = cb.ConstellationID;
GO

IF OBJECT_ID(N'dbo.vw_Mag6OrBrighter', N'V') IS NOT NULL
    DROP VIEW dbo.vw_Mag6OrBrighter;
GO
CREATE VIEW dbo.vw_Mag6OrBrighter AS
SELECT * FROM dbo.vw_CelestialBodySummary WHERE Magnitude IS NOT NULL AND Magnitude <= 6.0;
GO

IF OBJECT_ID(N'dbo.vw_Mag6OrFainter', N'V') IS NOT NULL
    DROP VIEW dbo.vw_Mag6OrFainter;
GO
CREATE VIEW dbo.vw_Mag6OrFainter AS
SELECT * FROM dbo.vw_CelestialBodySummary WHERE Magnitude IS NOT NULL AND Magnitude >= 6.0;
GO

-- ----------------------------------------------------------------------------
-- Seed: body types
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.BodyType)
INSERT INTO dbo.BodyType (TypeName, Description) VALUES
 (N'Star',              N'Self-luminous celestial body'),
 (N'Planet',            N'Major planet of the Solar System'),
 (N'Dwarf Planet',      N'Dwarf planet'),
 (N'Moon',              N'Natural satellite'),
 (N'Asteroid',          N'Small Solar System body'),
 (N'Comet',             N'Icy small body'),
 (N'Messier Object',    N'Entry in the Messier catalogue'),
 (N'Deep Sky Object',   N'Non-Messier nebula, cluster or galaxy'),
 (N'Galaxy',            N'Galaxy'),
 (N'Nebula',            N'Nebula'),
 (N'Star Cluster',      N'Open or globular cluster');
GO

-- ----------------------------------------------------------------------------
-- Seed: constellations (88 IAU constellations - abbreviated list of common ones)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Constellation)
INSERT INTO dbo.Constellation (Name, Abbreviation, Genitive) VALUES
 (N'Andromeda', N'And', N'Andromedae'),
 (N'Aquarius', N'Aqr', N'Aquarii'),
 (N'Aquila', N'Aql', N'Aquilae'),
 (N'Aries', N'Ari', N'Arietis'),
 (N'Auriga', N'Aur', N'Aurigae'),
 (N'Bootes', N'Boo', N'Bootis'),
 (N'Canis Major', N'CMa', N'Canis Majoris'),
 (N'Canis Minor', N'CMi', N'Canis Minoris'),
 (N'Cancer', N'Cnc', N'Cancri'),
 (N'Capricornus', N'Cap', N'Capricorni'),
 (N'Cassiopeia', N'Cas', N'Cassiopeiae'),
 (N'Centaurus', N'Cen', N'Centauri'),
 (N'Cepheus', N'Cep', N'Cephei'),
 (N'Cetus', N'Cet', N'Ceti'),
 (N'Crux', N'Cru', N'Crucis'),
 (N'Cygnus', N'Cyg', N'Cygni'),
 (N'Draco', N'Dra', N'Draconis'),
 (N'Gemini', N'Gem', N'Geminorum'),
 (N'Hercules', N'Her', N'Herculis'),
 (N'Leo', N'Leo', N'Leonis'),
 (N'Libra', N'Lib', N'Librae'),
 (N'Lyra', N'Lyr', N'Lyrae'),
 (N'Orion', N'Ori', N'Orionis'),
 (N'Pegasus', N'Peg', N'Pegasi'),
 (N'Perseus', N'Per', N'Persei'),
 (N'Pisces', N'Psc', N'Piscium'),
 (N'Sagittarius', N'Sgr', N'Sagittarii'),
 (N'Scorpius', N'Sco', N'Scorpii'),
 (N'Taurus', N'Tau', N'Tauri'),
 (N'Ursa Major', N'UMa', N'Ursae Majoris'),
 (N'Ursa Minor', N'UMi', N'Ursae Minoris'),
 (N'Virgo', N'Vir', N'Virginis');
GO

-- ----------------------------------------------------------------------------
-- Seed: sample celestial bodies
-- ----------------------------------------------------------------------------
DECLARE @tStar INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Star');
DECLARE @tPlanet INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Planet');
DECLARE @tMoon INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Moon');
DECLARE @tAsteroid INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Asteroid');
DECLARE @tComet INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Comet');
DECLARE @tMessier INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Messier Object');

DECLARE @cOri INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Orion');
DECLARE @cCMa INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Canis Major');
DECLARE @cUMa INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Ursa Major');
DECLARE @cUMi INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Ursa Minor');
DECLARE @cTau INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Taurus');
DECLARE @cAnd INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Andromeda');

-- Stars
INSERT INTO dbo.CelestialBody (Name, CommonName, BodyTypeID, Magnitude, RA_Hours, DEC_Degrees, Distance_LY, ConstellationID, Description)
VALUES
 (N'Sun', N'Sol', @tStar, -26.74, 0, 0, 0.0000158, NULL, N'G2V main-sequence star; centre of the Solar System'),
 (N'Sirius', N'Dog Star', @tStar, -1.46, 6.75248, -16.7161, 8.6, @cCMa, N'Brightest star in night sky'),
 (N'Betelgeuse', NULL, @tStar, 0.50, 5.91953, 7.4071, 700, @cOri, N'Red supergiant in Orion'),
 (N'Polaris', N'North Star', @tStar, 1.98, 2.53030, 89.2641, 433, @cUMi, N'Cepheid variable'),
 (N'Vega', NULL, @tStar, 0.03, 18.61565, 38.7837, 25, NULL, N'Alpha Lyrae'),
 (N'Rigel', NULL, @tStar, 0.13, 5.24230, -8.2016, 860, @cOri, N'Blue supergiant');
GO

-- Planets
DECLARE @tPlanet INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Planet');
INSERT INTO dbo.CelestialBody (Name, BodyTypeID, Magnitude, RA_Hours, DEC_Degrees, Distance_LY, Description)
VALUES
 (N'Mercury', @tPlanet, -0.4, 0, 0, 0.000006, N'Innermost planet'),
 (N'Venus', @tPlanet, -4.4, 0, 0, 0.0000108, N'Brightest planet'),
 (N'Mars', @tPlanet, -2.0, 0, 0, 0.000024, N'Red planet'),
 (N'Jupiter', @tPlanet, -2.2, 0, 0, 0.00008, N'Largest planet'),
 (N'Saturn', @tPlanet, 0.5, 0, 0, 0.00015, N'Ringed planet'),
 (N'Earth', @tPlanet, -3.9, 0, 0, 0, N'Our home planet');
GO

-- Moon
DECLARE @tMoon INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Moon');
INSERT INTO dbo.CelestialBody (Name, BodyTypeID, Magnitude, RA_Hours, DEC_Degrees, Distance_LY, Description)
VALUES (N'Moon', @tMoon, -12.74, 0, 0, 0.0000038, N'Earth natural satellite');
GO

INSERT INTO dbo.Moon (BodyID, ParentBodyID, DiameterKm, MassKg, OrbitalPeriodDays, SemiMajorAxisKm)
SELECT m.BodyID, e.BodyID, 3474.8, 73420000000000000000000.0, 27.32, 384400.0
FROM dbo.CelestialBody m CROSS JOIN dbo.CelestialBody e
WHERE m.Name = N'Moon' AND e.Name = N'Earth';
GO

-- Messier objects
DECLARE @tMessier INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Messier Object');
DECLARE @cAnd INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Andromeda');
DECLARE @cOri INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Orion');
DECLARE @cTau INT = (SELECT ConstellationID FROM dbo.Constellation WHERE Name=N'Taurus');
INSERT INTO dbo.CelestialBody (Name, CommonName, BodyTypeID, Magnitude, RA_Hours, DEC_Degrees, Distance_LY, ConstellationID, Description)
VALUES
 (N'M31', N'Andromeda Galaxy', @tMessier, 3.44, 0.7123, 41.269, 2537000, @cAnd, N'Spiral galaxy'),
 (N'M42', N'Orion Nebula', @tMessier, 4.0, 5.588, -5.391, 1344, @cOri, N'Emission nebula'),
 (N'M45', N'Pleiades', @tMessier, 1.6, 3.791, 24.105, 444, @cTau, N'Open star cluster');
GO

-- Link Messier detail rows
INSERT INTO dbo.MessierObject (BodyID, MessierNumber, ObjectType, Distance_KLY, ApparentSizeArcmin)
SELECT BodyID, 31, N'galaxy', 2537, 178 FROM dbo.CelestialBody WHERE Name=N'M31';
INSERT INTO dbo.MessierObject (BodyID, MessierNumber, ObjectType, Distance_KLY, ApparentSizeArcmin)
SELECT BodyID, 42, N'nebula', 1.344, 85 FROM dbo.CelestialBody WHERE Name=N'M42';
INSERT INTO dbo.MessierObject (BodyID, MessierNumber, ObjectType, Distance_KLY, ApparentSizeArcmin)
SELECT BodyID, 45, N'cluster', 0.444, 110 FROM dbo.CelestialBody WHERE Name=N'M45';
GO

-- Asteroid
DECLARE @tAsteroid INT = (SELECT BodyTypeID FROM dbo.BodyType WHERE TypeName=N'Asteroid');
INSERT INTO dbo.CelestialBody (Name, BodyTypeID, Magnitude, RA_Hours, DEC_Degrees, Distance_LY, Description)
VALUES (N'Ceres', @tAsteroid, 6.9, 0, 0, 0, N'Largest asteroid / dwarf planet');
GO

INSERT INTO dbo.Asteroid (BodyID, AsteroidClass, DiameterKm, OrbitalPeriodDays, SemiMajorAxisAU, Eccentricity)
SELECT BodyID, N'dwarf planet', 939.4, 1681.6, 2.768, 0.0757
FROM dbo.CelestialBody WHERE Name = N'Ceres';
GO

-- Star detail rows
INSERT INTO dbo.Star (BodyID, SpectralType, SurfaceTempK, MassSolar, RadiusSolar)
SELECT BodyID, N'G2V', 5778, 1.0, 1.0 FROM dbo.CelestialBody WHERE Name=N'Sun';
INSERT INTO dbo.Star (BodyID, SpectralType, SurfaceTempK, MassSolar, RadiusSolar)
SELECT BodyID, N'A1V', 9940, 2.06, 1.71 FROM dbo.CelestialBody WHERE Name=N'Sirius';
INSERT INTO dbo.Star (BodyID, SpectralType, SurfaceTempK, MassSolar, RadiusSolar)
SELECT BodyID, N'M1-M2Ia', 3500, 16.5, 887 FROM dbo.CelestialBody WHERE Name=N'Betelgeuse';
GO

-- Planet detail rows
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'terrestrial', 0.055, 0.383, 87.97, 0.387, 0 FROM dbo.CelestialBody WHERE Name=N'Mercury';
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'terrestrial', 0.815, 0.949, 224.7, 0.723, 0 FROM dbo.CelestialBody WHERE Name=N'Venus';
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'terrestrial', 0.107, 0.532, 686.98, 1.524, 0 FROM dbo.CelestialBody WHERE Name=N'Mars';
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'gas giant', 317.8, 11.21, 4332.59, 5.204, 1 FROM dbo.CelestialBody WHERE Name=N'Jupiter';
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'gas giant', 95.2, 9.45, 10759.22, 9.582, 1 FROM dbo.CelestialBody WHERE Name=N'Saturn';
INSERT INTO dbo.Planet (BodyID, PlanetClass, MassEarth, RadiusEarth, OrbitalPeriodDays, SemiMajorAxisAU, HasRings)
SELECT BodyID, N'terrestrial', 1.0, 1.0, 365.25, 1.0, 0 FROM dbo.CelestialBody WHERE Name=N'Earth';
GO

PRINT 'CelestialDatabase created and seeded successfully.';
GO
USE CelestialDatabase;
GO
IF COL_LENGTH('dbo.Constellation','VisibleFromNorthern') IS NULL
    ALTER TABLE dbo.Constellation ADD VisibleFromNorthern BIT NOT NULL CONSTRAINT DF_Constellation_VFN DEFAULT (1);
GO
UPDATE dbo.Constellation SET VisibleFromNorthern = 0
WHERE Name IN (N'Apus',N'Ara',N'Carina',N'Chamaeleon',N'Circinus',N'Crux',N'Dorado',N'Grus',N'Horologium',N'Hydrus',N'Indus',N'Mensa',N'Musca',N'Norma',N'Octans',N'Pavo',N'Phoenix',N'Pictor',N'Reticulum',N'Telescopium',N'Triangulum Australe',N'Tucana',N'Volans');
GO
IF OBJECT_ID('dbo.vw_NorthernConstellations','V') IS NOT NULL DROP VIEW dbo.vw_NorthernConstellations;
GO
CREATE VIEW dbo.vw_NorthernConstellations AS
SELECT * FROM dbo.Constellation WHERE VisibleFromNorthern = 1;
GO
PRINT 'Hemisphere column added.';
GO
