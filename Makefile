.PHONY : clean

CFLAGS= -fPIC -g
LDFLAGS= -shared

SOURCES = $(shell echo c/*.c)
HEADERS = $(shell echo c/*.h)
OBJECTS=$(SOURCES:.c=.o)

TARGET=lua/libhelper.so

all: $(TARGET)

clean:
	rm -f $(OBJECTS) $(TARGET)

$(TARGET) : $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) -o $@ $(LDFLAGS)
