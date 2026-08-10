/*
   K1OM fallback for the x86-64 SSE strcmp implementation.

   Use eglibc's generic C routine because Knights Corner rejects the inherited
   SSE instructions.  The included upstream source retains its LGPL notice.
*/
#include <string/strcmp.c>
