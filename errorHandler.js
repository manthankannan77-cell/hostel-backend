/**
 * Converts raw MySQL/SQL errors into user-friendly messages.
 */
function friendlyError(err) {
  const msg = err.message || "";
  const code = err.code || "";

  // ── Duplicate entry ──────────────────────────────────────────────
  if (code === "ER_DUP_ENTRY") {
    if (msg.includes("usn") || msg.includes("USN"))
      return "A student with this USN already exists.";
    if (msg.includes("email"))
      return "This email address is already registered.";
    if (msg.includes("mobile"))
      return "This mobile number is already registered.";
    if (msg.includes("room_no") || msg.includes("room"))
      return "A room with this number already exists.";
    if (msg.includes("block_id") || msg.includes("block"))
      return "A block with this ID already exists.";
    if (msg.includes("staff_id") || msg.includes("staff"))
      return "A staff member with this ID already exists.";
    if (msg.includes("txn_id"))
      return "A payment with this transaction ID already exists.";
    return "This record already exists. Please check for duplicates.";
  }

  // ── Foreign key violations (referenced row not found) ────────────
  if (code === "ER_NO_REFERENCED_ROW_2" || code === "ER_NO_REFERENCED_ROW") {
    if (msg.includes("room_ibfk") || msg.includes("room_no"))
      return "The room number you entered does not exist. Please add the room first.";
    if (
      msg.includes("block_ibfk") ||
      msg.includes("block_id") ||
      msg.includes("block")
    )
      return "The block you selected does not exist. Please add the block first.";
    if (
      msg.includes("student_ibfk") ||
      msg.includes("usn") ||
      msg.includes("student")
    )
      return "No student found with this USN. Please check and try again.";
    if (msg.includes("payment_ibfk") || msg.includes("payment"))
      return "No matching payment record found. Please check and try again.";
    if (msg.includes("complaint_ibfk") || msg.includes("complaint"))
      return "No matching complaint record found. Please check and try again.";
    if (msg.includes("visitor_ibfk") || msg.includes("visitor"))
      return "No matching visitor record found. Please check and try again.";
    if (msg.includes("staff_ibfk") || msg.includes("staff"))
      return "No matching staff record found. Please check and try again.";
    return "A related record was not found. Please check your inputs.";
  }

  // ── Row referenced by another table (can't delete) ───────────────
  if (code === "ER_ROW_IS_REFERENCED_2" || code === "ER_ROW_IS_REFERENCED") {
    if (msg.includes("student"))
      return "Cannot delete — this record is linked to one or more students.";
    if (msg.includes("room"))
      return "Cannot delete — this room is assigned to one or more students.";
    if (msg.includes("block"))
      return "Cannot delete — this block still has rooms or staff linked to it.";
    if (msg.includes("staff"))
      return "Cannot delete — this staff member is still linked to a block.";
    if (msg.includes("payment"))
      return "Cannot delete — this record has payments linked to it.";
    if (msg.includes("complaint"))
      return "Cannot delete — this record has complaints linked to it.";
    return "Cannot delete — this record is still being used elsewhere.";
  }

  // ── Stored procedure / signal errors (custom SQL errors) ─────────
  if (code === "ER_SIGNAL_EXCEPTION") {
    if (
      msg.toLowerCase().includes("full") ||
      msg.toLowerCase().includes("capacity")
    )
      return "This room is already full. Please choose a different room.";
    if (
      msg.toLowerCase().includes("not exist") ||
      msg.toLowerCase().includes("not found")
    )
      return "The room you entered does not exist. Please check the room number.";
    if (
      msg.toLowerCase().includes("already") ||
      msg.toLowerCase().includes("duplicate")
    )
      return "This student is already admitted. Duplicate entry not allowed.";
    const clean = msg.replace(/^.*SIGNAL:\s*/i, "").trim();
    if (clean.length > 0 && clean.length < 120) return clean;
  }

  // ── Data too long ────────────────────────────────────────────────
  if (code === "ER_DATA_TOO_LONG")
    return "One of the values you entered is too long. Please shorten it and try again.";

  // ── Incorrect integer / date values ─────────────────────────────
  if (code === "ER_TRUNCATED_WRONG_VALUE" || code === "ER_WRONG_VALUE")
    return "One of the values you entered is invalid. Please check the form fields.";

  // ── NULL not allowed ─────────────────────────────────────────────
  if (code === "ER_BAD_NULL_ERROR")
    return "A required field is missing. Please fill in all required fields.";

  // ── Fallback ─────────────────────────────────────────────────────
  return "Something went wrong. Please try again or contact support.";
}

module.exports = { friendlyError };
