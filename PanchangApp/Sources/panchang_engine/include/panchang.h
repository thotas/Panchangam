#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Computes the Panchang and returns a newly allocated C-string containing the JSON result.
 * The caller MUST free this string using `free_json_string()` when done.
 *
 * `location`: 0 = Hyderabad, 1 = DublinCa, 2 = HoustonTx, 3 = NewJersey, 4 = Philadelphia
 * `school`: 0 = Gantala, 1 = Nemani, 2 = TTD
 */
char *get_panchang_json(int year, int month, int day, int location_idx, int school_idx);

/**
 * Frees a JSON C-string previously allocated by `get_panchang_json`.
 */
void free_json_string(char *s);
