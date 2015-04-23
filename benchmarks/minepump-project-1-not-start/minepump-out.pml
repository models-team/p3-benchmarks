typedef features
{
    bool Start;
    bool Stop;
    bool MethaneAlarm;
    bool MethaneQuery;
    bool Low;
    bool Normal;
    bool High
};
 
features f;
           
mtype = { stop, start, alarm, low, medium, high, ready, running, stopped, methanestop, lowstop, commandMsg, alarmMsg, levelMsg };
 
chan cCmd = [0] of { mtype };
                             
chan cAlarm = [0] of { mtype };
                               
chan cMethane = [0] of { mtype };
                                 
chan cLevel = [0] of { mtype };
                               
mtype pstate = stopped;
                       
mtype readMsg = commandMsg;
                           
bool pumpOn = false;
                    
bool methane = false;
                     
mtype waterLevel = medium;
                          
mtype uwants = stop;
 
active proctype controller ()
{
    mtype pcommand = start;
    mtype level = medium;
    do
        :: atomic {
                      cCmd?pcommand;
                      readMsg = commandMsg
                  } -> if
                           :: (pcommand) == (stop) -> if
                                                          :: true -> if
                                                                         :: atomic {
                                                                                       (pstate) == (running);
                                                                                       pumpOn = false
                                                                                   }
                                                                         :: else -> skip
                                                                     fi;
                                                                     pstate = stopped
                                                          :: true -> skip
                                                      fi
                           :: (pcommand) == (start) -> if
                                                           :: false -> if
                                                                           :: atomic {
                                                                                         (pstate) != (running);
                                                                                         pstate = ready
                                                                                     }
                                                                           :: else -> skip
                                                                       fi
                                                           :: true -> skip
                                                       fi
                           :: else -> assert (false)
                       fi;
                       cCmd!pstate
        :: atomic {
                      cAlarm?_;
                      readMsg = alarmMsg
                  } -> if
                           :: true -> if
                                          :: atomic {
                                                        (pstate) == (running);
                                                        pumpOn = false
                                                    }
                                          :: else -> skip
                                      fi;
                                      pstate = methanestop
                           :: true -> skip
                       fi
        :: atomic {
                      cLevel?level;
                      readMsg = levelMsg
                  } -> if
                           :: (level) == (high) -> if
                                                       :: true -> if
                                                                      :: ((pstate) == (ready)) || ((pstate) == (lowstop)) -> if
                                                                                                                                 :: true -> skip;
                                                                                                                                            atomic {
                                                                                                                                                       cMethane!pstate;
                                                                                                                                                       cMethane?pstate;
                                                                                                                                                       if
                                                                                                                                                           :: (pstate) == (ready) -> pstate = running;
                                                                                                                                                                                     pumpOn = true
                                                                                                                                                           :: else -> skip
                                                                                                                                                       fi
                                                                                                                                                   }
                                                                                                                                 :: true -> skip;
                                                                                                                                            atomic {
                                                                                                                                                       pstate = running;
                                                                                                                                                       pumpOn = true
                                                                                                                                                   }
                                                                                                                             fi
                                                                      :: else -> skip
                                                                  fi
                                                       :: true -> skip
                                                   fi
                           :: (level) == (low) -> if
                                                      :: true -> if
                                                                     :: atomic {
                                                                                   (pstate) == (running);
                                                                                   pumpOn = false;
                                                                                   pstate = lowstop
                                                                               }
                                                                     :: else -> skip
                                                                 fi
                                                      :: true -> skip
                                                  fi
                           :: (level) == (medium) -> skip
                       fi
    od
};
 
active proctype user ()
{
    do
        :: if
               :: uwants = start
               :: uwants = stop
           fi -> cCmd!uwants;
                 cCmd?_
    od
};
 
active proctype methanealarm ()
{
    do
        :: methane = true -> cAlarm!alarm
        :: methane = false
    od
};
 
active proctype methanesensor ()
{
    do
        :: atomic {
                      cMethane?_;
                      if
                          :: methane -> cMethane!methanestop
                          :: ! (methane) -> cMethane!ready
                      fi
                  }
    od
};
 
active proctype watersensor ()
{
    do
        :: atomic {
                      if
                          :: (waterLevel) == (low) -> if
                                                          :: waterLevel = low
                                                          :: waterLevel = medium
                                                      fi
                          :: (waterLevel) == (medium) -> if
                                                             :: waterLevel = low
                                                             :: waterLevel = medium
                                                             :: waterLevel = high
                                                         fi
                          :: (waterLevel) == (high) -> if
                                                           :: waterLevel = medium
                                                           :: waterLevel = high
                                                       fi
                      fi;
                      cLevel!waterLevel
                  }
    od
};
 
never  {    /* []<>pumpOn */
T0_init:
	do
	:: ((pumpOn)) -> goto accept_S9
	:: (1) -> goto T0_init
	od;
accept_S9:
	do
	:: (1) -> goto T0_init
	od;
}
