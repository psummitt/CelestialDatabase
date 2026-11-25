namespace CelestialWeb.Models;

public class CelestialBody
{
    public long BodyID { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? CommonName { get; set; }
    public string BodyType { get; set; } = string.Empty;
    public decimal? Magnitude { get; set; }
    public decimal? RA_Hours { get; set; }
    public decimal? RA_Degrees { get; set; }
    public decimal? DEC_Degrees { get; set; }
    public decimal? Distance_LY { get; set; }
    public string? Constellation { get; set; }
    public string? ConstellationAbbr { get; set; }
    public string? OrbitsPlanet { get; set; }
    public string? Description { get; set; }
}

public class CelestialQuery
{
    public string? Name { get; set; }
    public string? BodyType { get; set; }
    public decimal? MinMagnitude { get; set; }
    public decimal? MaxMagnitude { get; set; }
    public decimal? MinRA { get; set; }
    public decimal? MaxRA { get; set; }
    public decimal? MinDEC { get; set; }
    public decimal? MaxDEC { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}