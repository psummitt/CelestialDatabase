<?php
require_once 'config.php';

$pageTitle = 'Celestial Query';
require 'header.php';

// Fetch body types
$bodyTypes = $pdo->query("SELECT TypeName FROM BodyType ORDER BY TypeName")->fetchAll(PDO::FETCH_COLUMN);

// Read filters
$name   = trim($_GET['name'] ?? '');
$type   = trim($_GET['bodyType'] ?? '');
$minMag = $_GET['minMag'] ?? '';
$maxMag = $_GET['maxMag'] ?? '';
$minRA  = $_GET['minRA'] ?? '';
$maxRA  = $_GET['maxRA'] ?? '';
$minDEC = $_GET['minDEC'] ?? '';
$maxDEC = $_GET['maxDEC'] ?? '';
$page   = max(1, (int)($_GET['page'] ?? 1));
$pageSize = 50;
$offset = ($page - 1) * $pageSize;

// Build query
$where = [];
$params = [];
if ($name !== '') {
    $where[] = "(cb.Name LIKE :name OR cb.CommonName LIKE :name)";
    $params[':name'] = "%$name%";
}
if ($type !== '') {
    $where[] = "bt.TypeName = :type";
    $params[':type'] = $type;
}
if ($minMag !== '' && is_numeric($minMag)) {
    $where[] = "cb.Magnitude >= :minMag";
    $params[':minMag'] = (float)$minMag;
}
if ($maxMag !== '' && is_numeric($maxMag)) {
    $where[] = "cb.Magnitude <= :maxMag";
    $params[':maxMag'] = (float)$maxMag;
}
if ($minRA !== '' && is_numeric($minRA)) {
    $where[] = "cb.RA_Hours >= :minRA";
    $params[':minRA'] = (float)$minRA;
}
if ($maxRA !== '' && is_numeric($maxRA)) {
    $where[] = "cb.RA_Hours <= :maxRA";
    $params[':maxRA'] = (float)$maxRA;
}
if ($minDEC !== '' && is_numeric($minDEC)) {
    $where[] = "cb.DEC_Degrees >= :minDEC";
    $params[':minDEC'] = (float)$minDEC;
}
if ($maxDEC !== '' && is_numeric($maxDEC)) {
    $where[] = "cb.DEC_Degrees <= :maxDEC";
    $params[':maxDEC'] = (float)$maxDEC;
}

$whereSql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Count
$countSql = "SELECT COUNT(*) FROM CelestialBody cb JOIN BodyType bt ON bt.BodyTypeID=cb.BodyTypeID LEFT JOIN Constellation c ON c.ConstellationID=cb.ConstellationID $whereSql";
$countStmt = $pdo->prepare($countSql);
$countStmt->execute($params);
$total = (int)$countStmt->fetchColumn();

// Data
$dataSql = "SELECT cb.BodyID, cb.Name, cb.CommonName, bt.TypeName AS BodyType, cb.Magnitude,
  cb.RA_Hours, cb.RA_Degrees, cb.DEC_Degrees, cb.Distance_LY, c.Name AS Constellation,
  mn.ParentBodyID, p.Name AS OrbitsPlanet
  FROM CelestialBody cb
  JOIN BodyType bt ON bt.BodyTypeID=cb.BodyTypeID
  LEFT JOIN Constellation c ON c.ConstellationID=cb.ConstellationID
  LEFT JOIN Moon mn ON mn.BodyID=cb.BodyID
  LEFT JOIN CelestialBody p ON p.BodyID=mn.ParentBodyID
  $whereSql
  ORDER BY cb.Name
  LIMIT :limit OFFSET :offset";
$dataStmt = $pdo->prepare($dataSql);
foreach ($params as $k => $v) {
    $dataStmt->bindValue($k, $v);
}
$dataStmt->bindValue(':limit', $pageSize, PDO::PARAM_INT);
$dataStmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$dataStmt->execute();
$rows = $dataStmt->fetchAll();
?>

<section aria-labelledby="query-heading">
    <h1 id="query-heading">Celestial Query</h1>
    <p>Search celestial bodies by name, type, magnitude, and coordinates.</p>

    <form method="get" action="query.php" class="row g-2 mb-3" role="search" aria-label="Celestial body search">
        <div class="col-md-3">
            <label for="name" class="form-label visually-hidden">Name contains</label>
            <input class="form-control" id="name" name="name" value="<?= htmlspecialchars($name) ?>" placeholder="Name contains...">
        </div>
        <div class="col-md-2">
            <label for="bodyType" class="form-label visually-hidden">Body type</label>
            <select class="form-select" id="bodyType" name="bodyType">
                <option value="">All types</option>
                <?php foreach ($bodyTypes as $t): ?>
                    <option value="<?= htmlspecialchars($t) ?>" <?= $type === $t ? 'selected' : '' ?>><?= htmlspecialchars($t) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="col-md-1">
            <label for="minMag" class="form-label visually-hidden">Min magnitude</label>
            <input class="form-control" id="minMag" name="minMag" value="<?= htmlspecialchars($minMag) ?>" placeholder="Min mag">
        </div>
        <div class="col-md-1">
            <label for="maxMag" class="form-label visually-hidden">Max magnitude</label>
            <input class="form-control" id="maxMag" name="maxMag" value="<?= htmlspecialchars($maxMag) ?>" placeholder="Max mag">
        </div>
        <div class="col-md-1">
            <label for="minRA" class="form-label visually-hidden">Min RA</label>
            <input class="form-control" id="minRA" name="minRA" value="<?= htmlspecialchars($minRA) ?>" placeholder="Min RA">
        </div>
        <div class="col-md-1">
            <label for="maxRA" class="form-label visually-hidden">Max RA</label>
            <input class="form-control" id="maxRA" name="maxRA" value="<?= htmlspecialchars($maxRA) ?>" placeholder="Max RA">
        </div>
        <div class="col-md-1">
            <label for="minDEC" class="form-label visually-hidden">Min DEC</label>
            <input class="form-control" id="minDEC" name="minDEC" value="<?= htmlspecialchars($minDEC) ?>" placeholder="Min DEC">
        </div>
        <div class="col-md-1">
            <label for="maxDEC" class="form-label visually-hidden">Max DEC</label>
            <input class="form-control" id="maxDEC" name="maxDEC" value="<?= htmlspecialchars($maxDEC) ?>" placeholder="Max DEC">
        </div>
        <div class="col-md-1">
            <button class="btn btn-primary" type="submit">Search</button>
        </div>
    </form>

    <p aria-live="polite"><strong><?= $total ?></strong> result(s). Page <?= $page ?>.</p>

    <div class="table-responsive">
        <table class="table table-striped table-sm">
            <caption class="visually-hidden">Celestial bodies matching search criteria</caption>
            <thead>
                <tr>
                    <th scope="col">Name</th>
                    <th scope="col">Common</th>
                    <th scope="col">Type</th>
                    <th scope="col">Mag</th>
                    <th scope="col">RA (h)</th>
                    <th scope="col">RA (°)</th>
                    <th scope="col">DEC (°)</th>
                    <th scope="col">Distance</th>
                    <th scope="col">Constellation</th>
                    <th scope="col">Orbits</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($rows as $b): ?>
                <tr>
                    <td><?= htmlspecialchars($b['Name']) ?></td>
                    <td><?= htmlspecialchars($b['CommonName'] ?? '') ?></td>
                    <td><?= htmlspecialchars($b['BodyType']) ?></td>
                    <td><?= $b['Magnitude'] !== null ? number_format((float)$b['Magnitude'], 2) : '' ?></td>
                    <td><?= $b['RA_Hours'] !== null ? number_format((float)$b['RA_Hours'], 4) : '' ?></td>
                    <td><?= $b['RA_Degrees'] !== null ? number_format((float)$b['RA_Degrees'], 4) : '' ?></td>
                    <td><?= $b['DEC_Degrees'] !== null ? number_format((float)$b['DEC_Degrees'], 4) : '' ?></td>
                    <td>
                        <?php if ($b['Distance_LY'] !== null): ?>
                            <?php if ((float)$b['Distance_LY'] < 1): ?>
                                <?= number_format((float)$b['Distance_LY'] * 63241.077, 2) ?> AU
                            <?php else: ?>
                                <?= number_format((float)$b['Distance_LY'], 0) ?> ly
                            <?php endif; ?>
                        <?php endif; ?>
                    </td>
                    <td><?= htmlspecialchars($b['Constellation'] ?? '') ?></td>
                    <td><?= htmlspecialchars($b['OrbitsPlanet'] ?? '') ?></td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($rows)): ?>
                <tr><td colspan="10">No results found.</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <?php if ($total > $pageSize): ?>
    <nav aria-label="Pagination">
        <ul class="pagination">
            <?php for ($p = 1; $p <= (int)ceil($total / $pageSize); $p++): ?>
                <?php
                $qs = http_build_query(array_merge($_GET, ['page' => $p]));
                ?>
                <li class="page-item <?= $p === $page ? 'active' : '' ?>">
                    <a class="page-link" href="query.php?<?= $qs ?>" <?= $p === $page ? 'aria-current="page"' : '' ?>><?= $p ?></a>
                </li>
            <?php endfor; ?>
        </ul>
    </nav>
    <?php endif; ?>
</section>
<?php require 'footer.php'; ?>