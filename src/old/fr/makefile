
OBJ   = main.o menustructs.o filerequest.o fr_structs.o

main:    $(OBJ)
         ln +Cd -o main $(OBJ) -lc

main.o:  main.c incl.pre
         cc main.c +iincl.pre

menustructs.o: menustructs.c incl.pre
         cc +b menustructs.c +iincl.pre

fr_structs.o:  fr_structs.c incl.pre
         cc +b fr_structs.c +iincl.pre

filerequest.o: filerequest.c incl.pre
         cc -t +b filerequest.c +iincl.pre

incl.pre:   incl.prelist
         cc -a -o nil: +hincl.pre incl.prelist
