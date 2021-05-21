######################################################################
# Name:      filterFRL
# Purpose:   <description>
# UPoC type: tps
# Args:      tps keyedlist containing the following keys:
#            MODE    run mode ("start", "run", "time" or "shutdown")
#            MSGID   message handle
#            CONTEXT tps caller context
#            ARGS    user-supplied arguments:
#                    <describe user-supplied args here>
#
# Returns:   tps disposition list:
#            <describe dispositions used here>
#
# Notes:     Cloverleaf Level 1/Basics
#            Simple tps proc to filter out the 
#            unneeded DISC messages in the 
#            inbound tps data
#
# History:   07/06/2010 - filterFRL - Lab 2-2
#                 

proc filterFRL { args } {
    keylget args MODE mode              	;# Fetch mode

    set dispList {}				;# Nothing to return

    switch -exact -- $mode {
        start {
        }

        run {
        keylget args MSGID mh
        
        # Get the message
	set msg [msgget $mh]

        # Set the variable trxId to the first 4 characters                   
	set trxId [string range $msg 0 3]      

        # If the trxId value is DISC or PADT then KILL the message
        # If the trxId value is anything else them CONTINUE
        # if {[string equal $trxId "DISC"]}

 	if {$trxId eq "DISC" || $trxId eq "PADT"} {
	lappend dispList "KILL $mh"
	} else {
	lappend dispList "CONTINUE $mh"
        }
	}

        time {
        }
        
        shutdown {
	}
    }

    return $dispList
}
