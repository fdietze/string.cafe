<?php

declare(strict_types=1);

function connect_to_database(): PDO
{
    $databaseUrl = getenv('DATABASE_URL');

    if ($databaseUrl === false || $databaseUrl === '') {
        throw new RuntimeException('DATABASE_URL must be set.');
    }

    $parts = parse_url($databaseUrl);

    if ($parts === false) {
        throw new RuntimeException(sprintf('Failed to parse DATABASE_URL: %s', $databaseUrl));
    }

    $host = $parts['host'] ?? null;
    $port = $parts['port'] ?? null;
    $databaseName = isset($parts['path']) ? ltrim($parts['path'], '/') : '';
    $username = $parts['user'] ?? '';
    $password = $parts['pass'] ?? '';

    if ($host === null || $port === null || $databaseName === '') {
        throw new RuntimeException(sprintf('DATABASE_URL is missing host, port, or database name: %s', $databaseUrl));
    }

    $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', $host, $port, $databaseName);

    return new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

function create_channel(PDO $database, string $channelName): void
{
    $trimmedName = trim($channelName);

    if ($trimmedName === '') {
        return;
    }

    $statement = $database->prepare('INSERT INTO channels (name) VALUES (:name) ON CONFLICT (name) DO NOTHING');
    $statement->execute([
        'name' => $trimmedName,
    ]);
}

function fetch_channels(PDO $database): array
{
    $statement = $database->query('SELECT id, name FROM channels ORDER BY name ASC');

    return $statement->fetchAll();
}

function redirect_to_index(): never
{
    header('Location: /', true, 303);
    exit;
}

$database = connect_to_database();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $submittedName = $_POST['name'] ?? '';

    if (!is_string($submittedName)) {
        throw new RuntimeException('Expected channel name form field to be a string.');
    }

    create_channel($database, $submittedName);
    redirect_to_index();
}

$channels = fetch_channels($database);
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>String Cafe</title>
  <style>
    body {
      font-family: sans-serif;
      margin: 2rem;
      max-width: 32rem;
    }

    h1 {
      margin-bottom: 1rem;
    }

    form {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1.5rem;
    }

    input,
    button {
      font: inherit;
      padding: 0.5rem 0.75rem;
    }

    input {
      flex: 1;
    }

    ul {
      padding-left: 1.25rem;
    }
  </style>
</head>
<body>
  <h1>Channels</h1>

  <form method="post">
    <input name="name" type="text" placeholder="New channel" required>
    <button type="submit">Add</button>
  </form>

  <ul>
    <?php foreach ($channels as $channel): ?>
      <li><?= htmlspecialchars($channel['name'], ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') ?></li>
    <?php endforeach; ?>
  </ul>
</body>
</html>
