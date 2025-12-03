-- =============================================================================
-- BK-RDR Supabase Schema Migration
-- =============================================================================
-- Migration to remove Google Drive fields (Supabase Storage Only)
-- Run these ALTER TABLE statements on your existing tables
-- =============================================================================

-- =============================================================================
-- 1. DOCUMENTS TABLE - Remove Google Drive columns
-- =============================================================================

-- Drop the storage_type check constraint
ALTER TABLE public.documents DROP CONSTRAINT IF EXISTS documents_storage_type_check;

-- Drop indexes for Google Drive columns
DROP INDEX IF EXISTS idx_documents_storage_type;
DROP INDEX IF EXISTS idx_documents_drive_file;

-- Remove Google Drive related columns
ALTER TABLE public.documents DROP COLUMN IF EXISTS storage_type;
ALTER TABLE public.documents DROP COLUMN IF EXISTS drive_file_id;
ALTER TABLE public.documents DROP COLUMN IF EXISTS drive_file_url;
ALTER TABLE public.documents DROP COLUMN IF EXISTS drive_annotated_file_id;

-- =============================================================================
-- 2. FOLDERS TABLE - Remove storage_type column
-- =============================================================================

-- Drop the storage_type check constraint
ALTER TABLE public.folders DROP CONSTRAINT IF EXISTS folders_storage_type_check;

-- Drop index for storage_type
DROP INDEX IF EXISTS idx_folders_storage;

-- Remove storage_type column
ALTER TABLE public.folders DROP COLUMN IF EXISTS storage_type;

-- =============================================================================
-- 3. ANNOTATIONS TABLE - No changes needed
-- =============================================================================
-- The annotations table doesn't have any Google Drive specific columns.
-- It references documents via document_id, which handles the relationship.

-- =============================================================================
-- FINAL SCHEMA AFTER MIGRATION
-- =============================================================================

-- DOCUMENTS TABLE (after migration):
-- +------------------+------------------------+----------------------------------+
-- | Column           | Type                   | Description                      |
-- +------------------+------------------------+----------------------------------+
-- | id               | UUID (PK)              | Primary key                      |
-- | title            | TEXT                   | Document title                   |
-- | file_path        | TEXT                   | Local file path                  |
-- | supabase_path    | TEXT                   | Path in Supabase storage         |
-- | original_name    | TEXT                   | Original filename                |
-- | file_size        | BIGINT                 | File size in bytes               |
-- | created_at       | TIMESTAMPTZ            | Creation timestamp               |
-- | last_opened      | TIMESTAMPTZ            | Last opened timestamp            |
-- | reading_progress | DOUBLE PRECISION       | Progress (0.0 to 1.0)            |
-- | is_favorite      | BOOLEAN                | Favorite flag                    |
-- | status           | TEXT                   | Status: new, uploading, etc.     |
-- | mime_type        | TEXT                   | MIME type (application/pdf)      |
-- | page_count       | INTEGER                | Total pages                      |
-- | last_page        | INTEGER                | Last page viewed                 |
-- | updated_at       | TIMESTAMPTZ            | Last update timestamp            |
-- | device_id        | TEXT                   | Device identifier                |
-- | folder_id        | UUID (FK)              | Reference to folders table       |
-- +------------------+------------------------+----------------------------------+

-- FOLDERS TABLE (after migration):
-- +------------------+------------------------+----------------------------------+
-- | Column           | Type                   | Description                      |
-- +------------------+------------------------+----------------------------------+
-- | id               | UUID (PK)              | Primary key                      |
-- | name             | TEXT                   | Folder name                      |
-- | parent_id        | UUID (FK, self-ref)    | Parent folder for nesting        |
-- | created_at       | TIMESTAMPTZ            | Creation timestamp               |
-- | updated_at       | TIMESTAMPTZ            | Last update timestamp            |
-- +------------------+------------------------+----------------------------------+

-- ANNOTATIONS TABLE (unchanged):
-- +------------------+------------------------+----------------------------------+
-- | Column           | Type                   | Description                      |
-- +------------------+------------------------+----------------------------------+
-- | id               | UUID (PK)              | Primary key                      |
-- | document_id      | UUID (FK)              | Reference to documents table     |
-- | page_number      | INTEGER                | Page number of annotation        |
-- | type             | TEXT                   | highlight, underline, drawing    |
-- |                  |                        | (textHighlight mapped to highlight)|
-- | content          | TEXT                   | Annotation text content          |
-- | color            | TEXT                   | Color hex code (#FFFF00)         |
-- | position         | JSONB                  | Position coordinates             |
-- | stroke_width     | DOUBLE PRECISION       | Stroke width for drawings        |
-- | stroke_points    | JSONB                  | Drawing stroke points            |
-- | is_synced        | BOOLEAN                | Sync status                      |
-- | local_id         | TEXT                   | Local identifier                 |
-- | created_at       | TIMESTAMPTZ            | Creation timestamp               |
-- | updated_at       | TIMESTAMPTZ            | Last update timestamp            |
-- | device_id        | TEXT                   | Device identifier                |
-- | version          | INTEGER                | Version number                   |
-- +------------------+------------------------+----------------------------------+

-- =============================================================================
-- NOTE: The app maps 'textHighlight' to 'highlight' for Supabase compatibility
-- If you want to add textHighlight as a valid type, run:
-- ALTER TABLE annotations DROP CONSTRAINT annotations_type_check;
-- ALTER TABLE annotations ADD CONSTRAINT annotations_type_check 
--   CHECK (type IN ('highlight', 'underline', 'drawing', 'note', 'textHighlight'));
-- =============================================================================

-- =============================================================================
-- VERIFICATION QUERIES (run after migration to verify)
-- =============================================================================

-- Check documents table structure
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'documents' ORDER BY ordinal_position;

-- Check folders table structure
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'folders' ORDER BY ordinal_position;

-- Check annotations table structure
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'annotations' ORDER BY ordinal_position;

-- =============================================================================
