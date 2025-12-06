-- =============================================================================
-- ANNOTATION TYPE CONSTRAINT UPDATE
-- =============================================================================
-- This SQL script updates the annotations table to allow 'textHighlight' type
-- Run this in your Supabase SQL Editor
-- =============================================================================

-- Step 1: Drop the old constraint
ALTER TABLE annotations DROP CONSTRAINT IF EXISTS annotations_type_check;

-- Step 2: Add the new constraint with 'textHighlight' included
ALTER TABLE annotations ADD CONSTRAINT annotations_type_check 
  CHECK (type IN ('highlight', 'underline', 'drawing', 'note', 'text', 'textHighlight', 'eraser'));

-- Verify the constraint was added
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'annotations'::regclass AND conname = 'annotations_type_check';

-- =============================================================================
-- RESULT:
-- After running this, your app will be able to:
-- - Save 'highlight' for paint-style highlights (messy freehand strokes)
-- - Save 'textHighlight' for text-detection highlights (crisp rectangles)
-- =============================================================================
