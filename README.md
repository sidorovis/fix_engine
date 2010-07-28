# pr-FIX

pr-FIX is a (minimalistic) implementation of the Financial Information eXchange
(FIX) Protocol, written in Ruby. The included files are presently:

<table>
<tr>
<td>README.md</td><td>This file</td>
</tr>
<tr>
<td>pr-fix.rb</td><td>The library itself. Depends on libxml.</td>
</tr>
<tr>
<td>banzai_test.rb</td><td>A simple test script that connects to the EXEC program from QuickFIX/J. Depends on rev.</td>
</tr>
<tr>
<td>cnx_test.rb</td><td>A simple test script that connects to the Currenex ECN and subscribes to and displays quotes for USD/JPY. Not recently tested. Depends on rev.</td>
</tr>
</table>

Author: Joseph Dunn <joseph@magnesium.net>
