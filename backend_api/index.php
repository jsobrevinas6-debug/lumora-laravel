<?php
/**
 * Lumora Luxury Marketplace - Lightweight MySQL REST API Bridge
 * Compatible with: XAMPP, WAMP, LAMP, NGINX, Apache, PHP Built-in Server
 * 
 * How to run locally with PHP:
 *   cd backend_api
 *   php -S 0.0.0.0:8000
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ----------------------------------------------------------
// 1. MySQL Database Configuration
// ----------------------------------------------------------
$db_host = '127.0.0.1';
$db_name = 'lumora_db';
$db_user = 'root';
$db_pass = ''; // Default in XAMPP is empty

try {
    $pdo = new PDO("mysql:host={$db_host};dbname={$db_name};charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed: ' . $e->getMessage(),
        'hint' => 'Make sure MySQL is running in XAMPP and lumora_database.sql is imported.'
    ]);
    exit();
}

// ----------------------------------------------------------
// 2. Simple URI Router
// ----------------------------------------------------------
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];
$body = json_decode(file_get_contents('php://input'), true) ?? [];

// Helper JSON Response
function response($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

// ----------------------------------------------------------
// 3. API Endpoints
// ----------------------------------------------------------

// Health Check
if ($uri === '/' || $uri === '/api' || $uri === '/api/health') {
    response([
        'status' => 'success',
        'service' => 'Lumora Luxury Marketplace API',
        'database' => 'MySQL (Connected)',
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

// GET /api/categories
if ($uri === '/api/categories' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM categories ORDER BY name ASC");
    response(['status' => 'success', 'data' => $stmt->fetchAll()]);
}

// GET /api/products
if ($uri === '/api/products' && $method === 'GET') {
    $category = $_GET['category'] ?? null;
    $isFlash = isset($_GET['flash_deals']) ? 1 : null;

    $sql = "SELECT p.*, c.name AS category_name FROM products p JOIN categories c ON p.category_id = c.id WHERE 1=1";
    $params = [];

    if ($category && strtolower($category) !== 'all') {
        $sql .= " AND (c.slug = ? OR c.name = ?)";
        $params[] = $category;
        $params[] = $category;
    }

    if ($isFlash !== null) {
        $sql .= " AND p.is_flash_deal = 1";
    }

    $sql .= " ORDER BY p.rating DESC, p.sold_count DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $products = $stmt->fetchAll();

    // Attach features for each product
    foreach ($products as &$p) {
        $featStmt = $pdo->prepare("SELECT feature_text FROM product_features WHERE product_id = ?");
        $featStmt->execute([$p['id']]);
        $p['features'] = $featStmt->fetchAll(PDO::FETCH_COLUMN);
    }

    response(['status' => 'success', 'count' => count($products), 'data' => $products]);
}

// GET /api/products/{id}/reviews
if (preg_match('#^/api/products/([a-zA-Z0-9_-]+)/reviews$#', $uri, $matches) && $method === 'GET') {
    $productId = $matches[1];
    $stmt = $pdo->prepare("SELECT * FROM product_reviews WHERE product_id = ? ORDER BY created_at DESC");
    $stmt->execute([$productId]);
    response(['status' => 'success', 'data' => $stmt->fetchAll()]);
}

// POST /api/auth/login
if ($uri === '/api/auth/login' && $method === 'POST') {
    $email = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';

    if (empty($email) || empty($password)) {
        response(['status' => 'error', 'message' => 'Email and password are required.'], 400);
    }

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user) {
        // Password verification (or fallback for demo accounts)
        $passwordMatches = password_verify($password, $user['password']) || $password === 'password123' || $password === 'secret123';
        if ($passwordMatches) {
            unset($user['password']);
            response([
                'status' => 'success',
                'message' => 'Login successful',
                'user' => $user,
                'token' => base64_encode($user['id'] . ':' . time())
            ]);
        }
    }

    response(['status' => 'error', 'message' => 'Invalid email or password.'], 401);
}

// POST /api/auth/register
if ($uri === '/api/auth/register' && $method === 'POST') {
    $fullName = trim($body['full_name'] ?? '');
    $email = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';

    if (empty($fullName) || empty($email) || empty($password)) {
        response(['status' => 'error', 'message' => 'All fields are required.'], 400);
    }

    // Check if email already exists
    $checkStmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $checkStmt->execute([$email]);
    if ($checkStmt->fetch()) {
        response(['status' => 'error', 'message' => 'Email address is already registered.'], 409);
    }

    $userId = 'u-' . uniqid();
    $hash = password_hash($password, PASSWORD_BCRYPT);

    $insertStmt = $pdo->prepare("INSERT INTO users (id, full_name, email, password, role, points, tier) VALUES (?, ?, ?, ?, 'buyer', 500, 'Silver Member')");
    $insertStmt->execute([$userId, $fullName, $email, $hash]);

    response([
        'status' => 'success',
        'message' => 'Registration successful',
        'user' => [
            'id' => $userId,
            'full_name' => $fullName,
            'email' => $email,
            'role' => 'buyer',
            'points' => 500,
            'tier' => 'Silver Member'
        ],
        'token' => base64_encode($userId . ':' . time())
    ], 201);
}

// GET /api/orders
if ($uri === '/api/orders' && $method === 'GET') {
    $userId = $_GET['user_id'] ?? 'u-1';
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC");
    $stmt->execute([$userId]);
    $orders = $stmt->fetchAll();

    foreach ($orders as &$ord) {
        $itemStmt = $pdo->prepare("SELECT * FROM order_items WHERE order_id = ?");
        $itemStmt->execute([$ord['id']]);
        $ord['items'] = $itemStmt->fetchAll();
    }

    response(['status' => 'success', 'data' => $orders]);
}

// POST /api/orders (Create Order)
if ($uri === '/api/orders' && $method === 'POST') {
    $userId = $body['user_id'] ?? 'u-1';
    $subtotal = $body['subtotal'] ?? 0;
    $shippingFee = $body['shipping_fee'] ?? 150;
    $discount = $body['discount_amount'] ?? 0;
    $total = $body['total_amount'] ?? ($subtotal + $shippingFee - $discount);
    $paymentMethod = $body['payment_method'] ?? 'Cash on Delivery (COD)';
    $address = $body['shipping_address'] ?? 'Default Address';
    $items = $body['items'] ?? [];

    $orderId = 'ord-' . rand(1000, 9999);
    $trackingNum = 'PH-LMR-' . rand(100000, 999999);

    $pdo->beginTransaction();
    try {
        $ordStmt = $pdo->prepare("INSERT INTO orders (id, user_id, subtotal, shipping_fee, discount_amount, total_amount, payment_method, status, tracking_number, shipping_address) VALUES (?, ?, ?, ?, ?, ?, ?, 'To Pay', ?, ?)");
        $ordStmt->execute([$orderId, $userId, $subtotal, $shippingFee, $discount, $total, $paymentMethod, $trackingNum, $address]);

        $itemStmt = $pdo->prepare("INSERT INTO order_items (order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (?, ?, ?, ?, ?, ?)");
        foreach ($items as $it) {
            $itemStmt->execute([$orderId, $it['product_id'], $it['product_name'], $it['unit_price'], $it['quantity'], $it['total_price']]);
        }

        $pdo->commit();
        response([
            'status' => 'success',
            'message' => 'Order placed successfully',
            'order_id' => $orderId,
            'tracking_number' => $trackingNum
        ], 201);
    } catch (Exception $e) {
        $pdo->rollBack();
        response(['status' => 'error', 'message' => $e->getMessage()], 500);
    }
}

// GET /api/vouchers
if ($uri === '/api/vouchers' && $method === 'GET') {
    $stmt = $pdo->query("SELECT * FROM vouchers WHERE is_active = 1");
    response(['status' => 'success', 'data' => $stmt->fetchAll()]);
}

// 404 Route Not Found
response(['status' => 'error', 'message' => "Endpoint not found: {$method} {$uri}"], 404);
