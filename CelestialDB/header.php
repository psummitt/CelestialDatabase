<?php
if (!isset($pageTitle)) { $pageTitle = "Summitt's Celestial Database"; }
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8') ?> - Summitt's Celestial Database</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <style>
        .skip-link { position: absolute; left: -9999px; top: 0; z-index: 999; padding: .5rem 1rem; background: #000; color: #fff; }
        .skip-link:focus { left: 0; }
        :focus { outline: 3px solid #0d6efd; outline-offset: 2px; }
        table { width: 100%; }
        .sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); border: 0; }
    </style>
</head>
<body>
<a href="#main-content" class="skip-link">Skip to main content</a>
<header>
    <nav class="navbar navbar-expand-sm navbar-light bg-white border-bottom box-shadow mb-3" aria-label="Main navigation">
        <div class="container-fluid">
            <a class="navbar-brand" href="index.php">Summitt's Celestial Database</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu" aria-controls="navMenu" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navMenu">
                <ul class="navbar-nav flex-grow-1">
                    <li class="nav-item"><a class="nav-link" href="index.php">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="query.php">Query</a></li>
                    <li class="nav-item"><a class="nav-link" href="moons.php">Moons</a></li>
                </ul>
            </div>
        </div>
    </nav>
</header>
<main id="main-content" class="container" tabindex="-1">