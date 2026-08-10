/* K1OM has no hardware lock elision.  The ordinary lock path is selected. */
int __elision_available attribute_hidden;
int __pthread_force_elision attribute_hidden;
