CC     = g++
CFLAGS = -c -Wall -O3 -fpic
OBJDIR = ../../obj/libsvm

all: $(OBJDIR)/svm.o

clean: ; $(RM) $(OBJDIR)/*.o

rebuild: clean all

$(OBJDIR)/svm.o: libsvm/svm.cpp

%.o:
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $^

.PHONY: all clean rebuild
