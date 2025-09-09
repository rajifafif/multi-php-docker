<?php
// PHP Multi-Version Development Environment Test Page
$phpVersion = phpversion();
$serverSoftware = $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown';
$documentRoot = $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown';
$scriptName = $_SERVER['SCRIPT_NAME'] ?? 'Unknown';

// Get system info
$systemInfo = [
    'PHP Version' => $phpVersion,
    'Server Software' => $serverSoftware,
    'Document Root' => $documentRoot,
    'Script Name' => $scriptName,
    'Current Time' => date('Y-m-d H:i:s'),
    'Server Name' => $_SERVER['SERVER_NAME'] ?? 'Unknown',
    'Request URI' => $_SERVER['REQUEST_URI'] ?? 'Unknown',
];

// Test database connections
$dbConnections = [];

// Test MySQL 8.4 (native)
try {
    $pdo84 = new PDO('mysql:host=127.0.0.1;port=3306;dbname=mysql', 'root', 'password');
    $dbConnections['MySQL 8.4 (Native)'] = 'Connected ✓';
} catch (Exception $e) {
    $dbConnections['MySQL 8.4 (Native)'] = 'Failed: ' . $e->getMessage();
}

// Test MySQL 8.0 (Docker)
try {
    $pdo80 = new PDO('mysql:host=mysql80;port=3306;dbname=mysql', 'root', 'password');
    $dbConnections['MySQL 8.0 (Docker)'] = 'Connected ✓';
} catch (Exception $e) {
    $dbConnections['MySQL 8.0 (Docker)'] = 'Failed: ' . $e->getMessage();
}

// Test extensions
$extensions = [
    'PDO MySQL' => extension_loaded('pdo_mysql'),
    'MySQLi' => extension_loaded('mysqli'),
    'cURL' => extension_loaded('curl'),
    'GD' => extension_loaded('gd'),
    'ZIP' => extension_loaded('zip'),
    'XML' => extension_loaded('xml'),
    'JSON' => extension_loaded('json'),
    'OpenSSL' => extension_loaded('openssl'),
    'MBString' => extension_loaded('mbstring'),
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Multi-Version Development Environment</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5rem;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            border-radius: 8px;
            background: #f8f9fa;
            border-left: 4px solid #007bff;
        }
        .section h2 {
            color: #333;
            margin-top: 0;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
        }
        .section h2::before {
            content: "🔧";
            margin-right: 10px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .info-item {
            background: white;
            padding: 15px;
            border-radius: 6px;
            border: 1px solid #e9ecef;
        }
        .info-label {
            font-weight: 600;
            color: #495057;
            margin-bottom: 5px;
        }
        .info-value {
            color: #333;
            font-family: 'Monaco', 'Consolas', monospace;
            background: #f1f3f4;
            padding: 5px 8px;
            border-radius: 4px;
            font-size: 0.9rem;
        }
        .status-success {
            color: #28a745;
            font-weight: 600;
        }
        .status-error {
            color: #dc3545;
            font-weight: 600;
        }
        .php-version {
            font-size: 2rem;
            font-weight: bold;
            color: #6f42c1;
            text-align: center;
            margin: 20px 0;
            padding: 20px;
            background: linear-gradient(45deg, #6f42c1, #007bff);
            color: white;
            border-radius: 10px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        .nav-links {
            text-align: center;
            margin: 30px 0;
            padding: 20px;
            background: #e3f2fd;
            border-radius: 8px;
        }
        .nav-links a {
            display: inline-block;
            margin: 5px 10px;
            padding: 10px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background-color 0.3s;
        }
        .nav-links a:hover {
            background: #0056b3;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐘 PHP Multi-Version Development Environment</h1>
        
        <div class="php-version">
            Running PHP <?php echo $phpVersion; ?>
        </div>

        <div class="nav-links">
            <strong>Available Applications:</strong><br>
            <a href="/hisv2">HIS v2 (PHP 5.6)</a>
            <a href="/ais">AIS (PHP 7.4)</a>
            <a href="/eprocurement">E-Procurement (PHP 7.4)</a>
            <a href="/his-pajri">HIS PAJRI (PHP 5.6)</a>
            <a href="/phpmyadmin">phpMyAdmin</a>
        </div>

        <div class="section">
            <h2>System Information</h2>
            <div class="info-grid">
                <?php foreach ($systemInfo as $label => $value): ?>
                <div class="info-item">
                    <div class="info-label"><?php echo htmlspecialchars($label); ?></div>
                    <div class="info-value"><?php echo htmlspecialchars($value); ?></div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>

        <div class="section">
            <h2>Database Connections</h2>
            <div class="info-grid">
                <?php foreach ($dbConnections as $db => $status): ?>
                <div class="info-item">
                    <div class="info-label"><?php echo htmlspecialchars($db); ?></div>
                    <div class="info-value <?php echo strpos($status, 'Connected') !== false ? 'status-success' : 'status-error'; ?>">
                        <?php echo htmlspecialchars($status); ?>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>

        <div class="section">
            <h2>PHP Extensions</h2>
            <div class="info-grid">
                <?php foreach ($extensions as $ext => $loaded): ?>
                <div class="info-item">
                    <div class="info-label"><?php echo htmlspecialchars($ext); ?></div>
                    <div class="info-value <?php echo $loaded ? 'status-success' : 'status-error'; ?>">
                        <?php echo $loaded ? 'Loaded ✓' : 'Not Loaded ✗'; ?>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>

        <div class="footer">
            <p>🐳 Docker Multi-Version PHP Development Environment</p>
            <p>Supports PHP 5.6, 7.4, 8.1, 8.2, 8.4 | MySQL 8.0 & 8.4 | Nginx</p>
        </div>
    </div>
</body>
</html>
