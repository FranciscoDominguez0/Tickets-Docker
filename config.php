<?php
/**
 * Configuration File
 * Ticket Management System
 */

if (!function_exists('mysqli_connect')) {
    die('Configuration Error: PHP mysqli extension is required. Please check: ' . php_ini_loaded_file());
}

// ==============================
// DATABASE CONFIG (DOCKER READY)
// ==============================
define('DB_HOST', 'db');
define('DB_PORT', '3306');

define('DB_USER', 'administrador');
define('DB_PASS', 'Panama26');

define('DB_NAME', 'tickets_db');

// ==============================
// APP CONFIG
// ==============================
define('APP_NAME', 'Sistema de Tickets');
define('TIMEZONE', 'America/Bogota');

// URL dinámica (sirve en Docker)
$__appUrl = 'http://localhost:8080';
if (!empty($_SERVER['HTTP_HOST'])) {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = (string)$_SERVER['HTTP_HOST'];
    $__appUrl = $scheme . '://' . $host;
}
define('APP_URL', $__appUrl);

define('ATTACHMENTS_DIR', __DIR__ . '/upload/uploads/attachments');

// ==============================
// SECURITY
// ==============================
define('SECRET_KEY', 'cambia-esto-en-produccion-con-algo-largo-y-aleatorio-2025');
define('CSRF_TIMEOUT', 3600);
define('SESSION_LIFETIME', 86400);

// ==============================
// INIT
// ==============================
date_default_timezone_set(TIMEZONE);

if (session_status() === PHP_SESSION_NONE) {

    $isSecure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');

    session_set_cookie_params([
        'lifetime' => SESSION_LIFETIME,
        'path' => '/',
        'domain' => '', // 🔥 vacío evita problemas en Docker
        'secure' => $isSecure,
        'httponly' => true,
        'samesite' => 'Lax'
    ]);

    session_start();
}

if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// ==============================
// DATABASE CONNECTION
// ==============================
try {
    $mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);

    if ($mysqli->connect_error) {
        throw new Exception('Connection failed: ' . $mysqli->connect_error);
    }

    $mysqli->set_charset('utf8mb4');

} catch (Exception $e) {
    die('Database Error: ' . $e->getMessage());
}

// ==============================
// AUTOLOAD
// ==============================
spl_autoload_register(function($class) {
    $file = __DIR__ . '/includes/' . $class . '.php';
    if (file_exists($file)) {
        require_once $file;
    }
});

// ==============================
// SESSION TIMEOUT
// ==============================
if (isset($_SESSION['user_login_time'])) {
    if (time() - $_SESSION['user_login_time'] > SESSION_LIFETIME) {
        session_destroy();
        header('Location: login.php?msg=session_expired');
        exit;
    } else {
        $_SESSION['user_login_time'] = time();
    }
}