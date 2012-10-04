Fix Engine 
==========

Fix Engine is a (minimalistic) implementation of the Financial Information eXchange 
with client-server multithread workarounds (based on pr-fix: https://github.com/uritu/pr-fix, by Joseph Dunn <joseph@magnesium.net> ).

Common sub-library:
 * system_processor - special class that regulate server workaround.
 * tcp_client - class that works with tcp socket, protect it from different exceptions, and made read method separated from main thread.
 * tcp_server - class that separate accept and connected clients read threads to separate threads (so main program could process them asynchronius).
 * timer - class that do some action with user defined sleep_intervale

Fix sub-library:
 * message - class generates fix_message
 * response - class that created for processing fix_message
 * session - class that define session defines for fix messages

Author: Ivan Sidarau <ivan.sidarau@gmail.com>
