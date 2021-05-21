######################################################################
# Name:      tpsParseHL7
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
# Notes:     <put your notes here>
#
# History:   <date> <name> <comments>
#                 

proc tpsParseHL7 { args } {
    global HciConnName                             ;# Name of thread
    
    keylget args MODE mode                         ;# Fetch mode
    set ctx ""   ; keylget args CONTEXT ctx        ;# Fetch tps caller context
    set uargs {} ; keylget args ARGS uargs         ;# Fetch user-supplied args

    set debug 0  ;                                 ;# Fetch user argument DEBUG and
    catch {keylget uargs DEBUG debug}              ;# assume uargs is a keyed list

    set module "tpsParseHL7/$HciConnName/$ctx" ;# Use this before every echo/puts,
                                                   ;# it describes where the text came from

    set dispList {}                                ;# Nothing to return

    switch -exact -- $mode {
        start {
            # Perform special init functions
            # N.B.: there may or may not be a MSGID key in args
            
            if { $debug } {
                puts stdout "$module: Starting in debug mode..."
            }
        }

        run {
            # 'run' mode always has a MSGID; fetch and process it
            
            keylget args MSGID mh

            # Grab the message from the message handle
            set msg [msgget $mh]

            # Grab the field Separator
            #set fieldSep [string index $msg 3]

            # Grab the SubField Separator
            #set subSep [string index $msg 4]

            # Split the message on the carriage return and set a list of segments
            #set segList [split $msg \r]

            # Get the PID segment from the list of segments
            #set segment [lsearch -inline -regexp $segList ^PID]

            # Split the segment on the field Separator, and get a list of fields
            #set fieldList [split $segment $fieldSep]

            # Grab the Patient Name PID.#5
            #set field [lindex $fieldList 5]

            # Convert Patient Name to upper case
            #set field [string toupper $field]

            # Replace the PID.#5 with the new patient name
            #set fieldList [lreplace $fieldList 5 5 $field]

            # Convert our list of PID fields, back to segment
            #set segment [join $fieldList $fieldSep]

            # Find where the PID segment was in the list of segments
            #set position [lsearch -regexp $segList ^PID]

            # Replace the segment in the right spot of the segment list
            #set segList [lreplace $segList $position $position $segment]

            # Join our list of segments with the carriage return
            #set msg [join $segList \r]

            # Replace the message in the message handle
            #msgset $mh $msg
                        
            lappend dispList "CONTINUE $mh"
        }

        time {
            # Timer-based processing
            # N.B.: there may or may not be a MSGID key in args
            
        }
        
        shutdown {
            # Doing some clean-up work 
            
        }
        
        default {
            error "Unknown mode '$mode' in $module"
        }
    }

    return $dispList
}
