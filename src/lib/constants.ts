// Limits that mirror the database checks in supabase/migrations/ (constants.test.ts).
export const DISPLAY_NAME_MAX_LENGTH = 60;
export const LIST_TITLE_MAX_LENGTH = 60;
export const WISH_TITLE_MAX_LENGTH = 120;
export const WISH_NOTE_MAX_LENGTH = 1000;
export const WISH_URL_MAX_LENGTH = 2048;
export const STORE_NAME_MAX_LENGTH = 120;
export const IMAGE_MAX_BYTES = 5 * 1024 * 1024;

// Photos are resized and re-encoded to JPEG on the phone before upload.
export const IMAGE_MAX_EDGE_PX = 1600;
export const IMAGE_JPEG_QUALITY = 0.8;
