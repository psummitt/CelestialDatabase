<?php
require_once 'config.php';
$pageTitle = 'Moons';
require 'header.php';

$rows = $pdo->query("SELECT Moon, OrbitsPlanet FROM vw_MoonsWithPlanets ORDER BY OrbitsPlanet, Moon")->fetchAll();
?>
<section aria-labelledby="moons-heading">
    <h1 id="moons-heading">Moons and Their Planets</h1>
    <table class="table table-striped">
        <caption>Moons and the planets they orbit</caption>
        <thead>
            <tr>
                <th scope="col">Moon</th>
                <th scope="col">Orbits Planet</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($rows as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['Moon']) ?></td>
                <td><?= htmlspecialchars($r['OrbitsPlanet']) ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php require 'footer.php'; ?>