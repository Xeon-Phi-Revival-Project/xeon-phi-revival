/* K1OM has no hardware lock elision.  */
#ifndef _K1OM_FORCE_ELISION_H
#define _K1OM_FORCE_ELISION_H 1

#define FORCE_ELISION(mutex, statement) ((void) 0)

#endif
