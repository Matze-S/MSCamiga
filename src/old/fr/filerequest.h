
/*
**  filerequest.h
**
**  filerequester-main-include-file
*/

#define C_GROUND 0
#define C_TEXT 1
#define C_BACK 2
#define C_FRONT 3
#define REQWIDTH 280
#define REQHEIGHT 158
#define TITLEHEIGHT 12
#define EG_WIDTH 80
#define EG_HEIGHT 20
#define SG_WIDTH 188
#define SG_HEIGHT 9
#define UDG_WIDTH 30
#define UDG_HEIGHT 18
#define UG_TOPEDGE 8+TITLEHEIGHT
#define DG_TOPEDGE 6+PG_TOPEDGE+PG_HEIGHT
#define PG_WIDTH 10
#define PG_HEIGHT 26
#define PG_TOPEDGE 6+UG_TOPEDGE+UDG_HEIGHT
#define FG_WIDTH 208
#define FG_HEIGHT 64

#define EX ((FG_WIDTH)/8)
#define EY ((FG_HEIGHT)/8)

#define GID_ENDGADGET 16
#define GID_CANCEL 17
#define GID_FILE 18
#define GID_PATH 19
#define GID_UP 20
#define GID_DOWN 21
#define GID_PROP 22
#define GID_SELECT 23
