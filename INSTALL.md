# Installation

## 1. Prerequisites

- Elixir **~> 1.15** and Erlang/OTP must be on your PATH. Verify with:

  ```bash
  elixir --version
  ```

## 2. Get the Code

Clone the repository (or download the source code) and navigate into the project directory.

## 3. Install Dependencies

Fetch Elixir and asset dependencies:

```bash
mix deps.get
```

## 4. Environment Variables

Copy the example environment file and edit as needed:

```bash
cp .env.example .env
```

The only variable used is `FONTS_DIR` (path to custom fonts). If you do not need custom fonts, you can leave it empty.

## 5. Database Setup

Drift uses **SQLite3** (via `ecto_sqlite3`), so no external database server is required. The following command creates the database, runs migrations, and seeds demo data:

```bash
mix ecto.setup
```

Alternatively, you can use the project alias that bundles dependency installation, database setup, and compilation:

```bash
mix setup
```

## 6. Run the Development Server

Start the Phoenix server with:

```bash
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

## 7. Run Tests

Execute the test suite:

```bash
mix test
```

The test command automatically creates and migrates a test database (defined in `config/test.exs`).

## 8. Build for Production

To generate a release:

```bash
MIX_ENV=prod mix release
```

If you need to compile Tailwind CSS assets for production, run the custom alias:

```bash
mix assets.build
```

## 9. Troubleshooting

- **Elixir version mismatch** – Ensure your Elixir version satisfies `~> 1.15`. Use `asdf` or `mise` to manage versions if needed.
- **SQLite3 missing** – The `ecto_sqlite3` library bundles its own SQLite3, so no system installation is required. If you encounter compile errors, ensure you have a C compiler toolchain.
- **Tailwind not compiled** – If the layout appears unstyled, run `mix assets.build` and restart the server.
- **Database errors** – You can reset the database with `mix ecto.reset` to start fresh.