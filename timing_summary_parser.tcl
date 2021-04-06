# Taken from the Xilinx forum, All credits to woodsd:
# https://forums.xilinx.com/t5/Vivado-TCL-Community/How-can-I-get-WNS-TNS-and-run-time-without-opening-design-runs/m-p/760618/highlight/true#M5549


proc getTimingInfo { {report {}} } {
   if {$report == {}} { 
      set report [split [report_timing_summary -no_detailed_paths -no_check_timing -no_header -return_string] \n]
   } else {
      set report [split $report \n]
   }

   foreach {wns tns tnsFailingEp tnsTotalEp whs ths thsFailingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [list {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A} {N/A}] { 
      break 
   }
   if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
      foreach {wns tns tnsFailingEp tnsTotalEp whs ths thsFailingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { 
         break 
      }
   }
   puts "Setup:\n\t| WNS=$wns | TNS=$tns | Failing Endpoints=$tnsFailingEp | Total Endpoints=$tnsTotalEp |"
   puts "Hold:\n\t| WHS=$whs | THS=$ths | Failing Endpoints=$thsFailingEp | Total Endpoints=$thsTotalEp |"
   puts "Pulse Width:\n\t | WPWS=$wpws | TPWS=$tpws | Failing Endpoints=$tpwsFailingEp | Total Endpoints=$tpwsTotalEp |\n\n"
}
