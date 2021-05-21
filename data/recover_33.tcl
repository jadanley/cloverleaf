######################################################################
# Tcl library of recovery procedures for release 3.3.0P and above
#
#	Required procedures:
#	save_ob_msg:    Configure as SEND-OK.   Saves outbound message in memory
#	kill_ob_save:   Configure as IB REPLY.  Kills saved msg when reply rcvd
#	resend_ob_msg:  Configure as REPLY GEN. Resends OB msg on timeout
#	                                        Resends OB msg on thread start
#
#	Optional procedures:
#	validate_reply: Configure as first IB REPLY.  Optional resend based
#	                                              on acknowledgement


######################################################################
# save_ob_msg - Save the message we just send.  Use as a "send_ok"
#				proc ONLY!
#
# Args: tps keyedlist containing:
#       MODE    run mode ("start" or "run")
#       MSGID   message handle
#       ARGS    keyed list of user arguments containing:
#               <describe user supplied args here>
#
# Returns: tps keyed list containing
#       CONTINUE	= all msgs
#
# Notes:
#		Normally used to hold a message in memory if it needs to be
#		re-sent based on a reply.
#
#		Use the 'kill_ob_save' proc to clean up after msg has been
#		processed.
#
proc save_ob_msg { args } {

    global ob_save						;# OB message saved here
    global HciConnName

    set module "(SAVE_OB_MSG/$HciConnName)"

    set dispList {}

    keylget args MODE mode              ;# What mode are we in
    switch -exact -- $mode {
        start {
            # Initialize the ob_save global
                set ob_save ""
        }

        run {
            keylget args CONTEXT ctx
            keylget args MSGID mh
            if {$ctx != "send_data_ok"} {
                echo "$module Called with invalid context!"
                echo "$module Should be SEND OK for OB DATA only."
                echo "$module Continuing msg."
                lappend dispList "CONTINUE $mh"
            }

            if {$ob_save == ""} {
                set ob_save $mh
                # Do NOT return msg to the engine
            } else {
                # Something bad happened.  Proc that uses the saved msg
                # did not clean up after itself!
                set errmsg "$module FATAL ERROR! Attempt to save over\
                message '$ob_save' with message '$mh'"
                echo "$module $errmsg"

                echo "$module Existing msg:"
                msgdump $ob_save
                echo "$module New msg:"
                msgdump $mh

                error $errmsg; # Put msg in errdb
            }
        }

        default {
            echo "Unknown mode in <save_ob_msg>: '$mode'"
        }
    }
    return $dispList
}

######################################################################
# kill_ob_save - 	Kill the message saved by the 'save_ob_msg' proc.
#
# Args: tps keyedlist containing:
#       MODE    run mode ("start" or "run")
#       MSGID   message handle
#       ARGS    keyed list of user arguments containing:
#				(nothing)
#
# Returns: tps keyed list containing
#       CONTINUE	= all msgs
#	KILL		= kill the 'ob_save' message.
#
proc kill_ob_save { args } {

    global ob_save                      ;# OB message saved here
    global HciConnName

    set module "(KILL_OB_SAVE/$HciConnName)"

    set dispList {}

    keylget args MODE mode              ;# What mode are we in
    switch -exact -- $mode {
        start {
            # Initialize the ob_save global 
                set ob_save ""
        }

        run {
            keylget args MSGID mh

            # Null out the global variable
            set my_mh $ob_save
            set ob_save ""

            lappend dispList "CONTINUE $mh"
            lappend dispList "KILL $my_mh"
        }

        default {
            echo "Unknown mode in kill_ob_save: '$mode'"
        }
    }
    return $dispList
}

######################################################################
# resend_ob_msg - 	If we didn't receive a reply, then resend the msg
#                       and save it (if save_ob_msg is being used)
#
# Args: tps keyedlist containing:
#       MODE    run mode ("start" or "run")
#       MSGID   message handle
#       ARGS    keyed list of user arguments containing:
#				(nothing)
#
# Returns: tps keyed list containing
#       CONTINUE	= all msgs
#
# usage:    'Inbound>Configure...Reply Generation...'
#
proc resend_ob_msg { args } {

    global ob_save                      ;# OB message saved here
    global HciConnName

    set module "(RESEND_OB_MSG/$HciConnName)"

    set dispList {}

    keylget args MODE mode              ;# What mode are we in
    switch -exact -- $mode {
        start {
            # Initialize the ob_save global 
                set ob_save ""
        }

        run {
            keylget args CONTEXT ctx
            keylget args MSGID mh
            if {$ctx != "reply_gen"} {
                echo "$module Called with invalid context!"
                echo "$module Should be REPLY GENERATION only"
                echo "$module Continuing msg."
                lappend dispList "CONTINUE $mh"
            }

            set ret_list ""
            if {$ob_save != ""} {
                # The save_ob_msg proc is being used -- destroy the new msg
                # and resend the saved msg.
                # Clear the global -- the msg will be re-saved after send.
                set my_mh $ob_save
                set ob_save ""
                lappend dispList "PROTO $my_mh"
                lappend dispList "KILL $mh"
            } else {
                lappend dispList "PROTO $mh"
                echo "$module No saved msg to resend.  Resending using new copy..."
            }
            # Resend the msg
            echo "$module No response within timeout or state 14 message resent."
            echo "$module Resending msg at [fmtclock [getclock]]"
        }

        default {
            echo "Unknown mode in <resend_ob_msg>: '$mode'"
        }
    }
    return $dispList
}

######################################################################
# Name:		validate_reply
# Purpose:	Validate an inbound reply, resend message if necessary.
# UPoC type:	tps
# Args: 	tps keyedlist containing the following keys:
#       	MODE    run mode ("start" or "run")
#       	MSGID   message handle
#       	ARGS    user-supplied arguments:
#					(none)
#
# Returns: tps disposition list:
#			CONTINUE	= reply OK, continue it
#
#			KILLREPLY	= reply not OK, kill it
#			PROTO		= reply not OK, resend original message
#
# Notes:
#		Needs the following procs to run correctly:
#			save_ob_msg (OB DATA TPS)
#			kill_ob_save (IB REPLY TPS -- AFTER THIS PROC!)
#			resend_ob_msg (REPLY GEN TPS)
#			recover_state_14 (PROTO STARTUP TPS)
#
#	THIS PROCEDURE IS FOR EXAMPLE PURPOSES ONLY.  YOU SHOULD MODIFY
#	THE PROCEDURE TO MATCH THE ACKNOWLEDGEMENT SPECIFICATIONS OF THE
#	REMOTE SYSTEM.
#			
proc validate_reply { args } {

    global ob_save
    global HciConnName

    set module "(RESEND_OB_MSG/$HciConnName)"

    set dispList {}

    keylget args MODE mode              	;# Fetch mode
    switch -exact -- $mode {
        start {
            # Perform special init functions
        }

        run {
            keylget args MSGID mh

            set data [msgget $mh]
            if [cequal $data "ACK"] {
                # Reply OK, pass it along
                lappend dispList "CONTINUE $mh"
            } else {
                # ob_save is global holding message we sent
                set my_mh $ob_save
                set ob_save ""		;# Needs to be nulled out!

                # Kill the reply and resend the original message
                lappend dispList "KILLREPLY $mh"
		lappend dispList "PROTO $my_mh"
            }
        }

        default {
            error "Unknown mode '$mode' in validate_reply"
        }
    }
    return $dispList
}
