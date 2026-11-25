<?php
require_once 'config.php';
$pageTitle = 'About';
require 'header.php';
?>
<section aria-labelledby="about-heading">
    <h1 id="about-heading">About Summitt's Celestial Database</h1>
    <p class="lead">
        A MySQL catalog of celestial bodies visible from Earth, including stars, planets,
        moons, asteroids, comets, Messier objects, and more — each with Right Ascension (RA)
        and Declination (DEC) coordinates.
    </p>

    <h2>Contents</h2>
    <ul>
        <li><strong>9,100+ stars</strong> from a bright-star catalog (with spectral types and distances)</li>
        <li><strong>110 Messier objects</strong> (galaxies, nebulae, clusters)</li>
        <li><strong>Planets &amp; dwarf planets</strong> of the Solar System</li>
        <li><strong>21 moons</strong>, including major satellites</li>
        <li><strong>Asteroids &amp; comets</strong></li>
        <li><strong>88 constellations</strong> (full IAU set), with Northern-Hemisphere visibility flags</li>
    </ul>

    <h2>Query the catalog</h2>
    <p>
        Use the <a href="query.php">Celestial Query</a> page to search by
        name, body type, magnitude range, and RA/DEC coordinates.
    </p>

    <h2>Database</h2>
    <p>
        Server: <code>localhost</code> (MySQL)<br>
        Database: <code>celestialdatabase</code>
    </p>
</section>
<?php require 'footer.php'; ?>