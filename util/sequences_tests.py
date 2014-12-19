#!/usr/bin/python -u
'''
Copyright (c) 2014, IETR/INSA of Rennes
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the IETR/INSA of Rennes nor the names of its
    contributors may be used to endorse or promote products derived from this
    software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
'''

from __future__ import print_function
import os, sys, re, signal, time
import argparse, subprocess, csv

VERSION = "0.3"

PATH='path'
FRAMES='nbFrames'
SIZE='size'

def main():
    global args

    errorsCount = 0
    warningsCount = 0

    fileList = parseSequencesList()

    baseCommand = buildCommand()

    for sequence in fileList:

        # Make a copy of the base command line, to avoid
        # multiple -i and -o options in the final command line
        commandLine = list(baseCommand)

        inputFile = sequence[PATH]
        if not os.path.exists(inputFile):
            warning("input file", inputFile, "does not exists")
            warningsCount += 1
            continue
        elif not os.access(inputFile, os.R_OK):
            warning("input file", inputFile, "is not readable")
            warningsCount += 1
            continue

        commandLine.extend(["-i", inputFile])

        if args.checkYuv:
            yuvFile = getYUVFile(inputFile)
            if not os.path.exists(yuvFile):
                warning("YUV file", yuvFile, "does not exists")
                warningsCount += 1
                continue
            elif not os.access(yuvFile, os.R_OK):
                warning("YUV file", yuvFile, "is not readable")
                warningsCount += 1
                continue
            commandLine.extend(["-o", yuvFile])

        setNbFramesToDecode(sequence, commandLine)

        traceMsg = "Try to decode " + inputFile
        if args.checkYuv:
            traceMsg += " / check with YUV " + yuvFile

        if args.verbose:
            traceMsg += " with command \n" + ' '.join(commandLine)

        print(traceMsg)
        returnCode = runSubProcess(commandLine)
        if returnCode != 0:
            sys.stderr.write("Error, command returned code " + str(returnCode) + '\n')
            errorsCount += 1
        else:
            print("Process finished correctly")
    # endfor

    if errorsCount != 0:
        ws, es = "", ""
        if errorsCount > 1 : es = "s"
        if warningsCount > 1 : ws = "s"
        sys.exit("The test suite finished with " + str(errorsCount) + " error"+es+" and " + str(warningsCount) + " warning"+ws+".")
    elif warningsCount != 0:
        s = ""
        if warningsCount > 1 : s = "s"
        warning("The test suite finished without error but", warningsCount, "warning"+s+".")
    else :
        print("The test suite finished without error !")

# Parse the inputList given in argument, and extract information about videos
def parseSequencesList():
    global args

    patternString = None
    if args.regexp:
        patternString = args.regexp
    elif args.filter:
        patternString = args.filter.replace('.', '\.')
        patternString = patternString.replace('?', '.')
        patternString = patternString.replace('*', '(.+)')

    if patternString:
        pattern = re.compile(patternString)
    else:
        pattern = None

    cptEntries = 0
    cptFiltered = 0

    result = []
    with open(args.inputList, 'r') as csvfile:
        # Reader ignores lines starting with '#', and compute automatically values in a
        # dictionary indexed by (PATH, FRAMES, SIZE)
        entries = csv.DictReader(
            (row for row in csvfile if not row.startswith('#')),
            fieldnames=(PATH, FRAMES, SIZE),
            skipinitialspace=True, delimiter=',')
        for sequenceEntry in entries:
            cptEntries += 1
            if pattern and not pattern.match(sequenceEntry[PATH]):
                continue

            cptFiltered += 1
            if args.directory:
                sequenceEntry[PATH] = args.directory + os.sep + sequenceEntry[PATH]

            sequenceEntry[PATH] = sequenceEntry[PATH].replace('/', os.sep)
            result.append(sequenceEntry)
        #endfor

    if args.verbose:
        print(cptEntries, "sequences found in", args.inputList)
        if pattern:
            print(len(result), "selected by '"+pattern.pattern+"'")
    return result

def buildCommand():
    global args
    global additional_args
    commandToRun = [args.executable]

    if additional_args:
        # User used -args to add command line arguments
        commandToRun.extend(additional_args)

    return commandToRun

# Replace the suffix of a path by the 'yuv' extension. Returns the resulting YUV path
def getYUVFile(sequencePath):
    return '.'.join(sequencePath.split('.')[:-1]) + ".yuv"

def setNbFramesToDecode(sequence, command):
    global args
    # Stop decoding when all frames have been processed
    if not args.noNbFrames:
        if sequence[FRAMES]:
            nbFrames = int(sequence[FRAMES]) * args.nbLoop
            command.extend(["-f", str(nbFrames)])
        else:
            command.extend(["-l", str(args.nbLoop)])
            warning("Input list doesn't contains the number of frames for "+inputFile+"\n"+
                "As fallback, '-l "+str(args.nbLoop)+"' has been added to the command line.")

# Run commandLine in a sub-process. Returns true if the command ends with a returnCode == 0
def runSubProcess(commandLine):
    global p
    p = subprocess.Popen(commandLine)
    p.wait()
    return p.poll()

def configureCommandLine():
    # Help on arparse usage module : http://docs.python.org/library/argparse.html#module-argparse
    global parser

    parser = argparse.ArgumentParser(add_help=False,
        description='Test a list of video sequences. All unrecognised arguments given to this script will be used on EXECUTABLE command line')

    mandatory = parser.add_argument_group(title="Mandatory arguments")
    mandatory.add_argument("-e", "--executable", action="store", dest="executable", required=True,
                        help="Main executable to run")
    mandatory.add_argument("-i", "--inputList", action="store", dest="inputList", required=True,
                        help="Path to the file containing list of sequences to decode")

    optional = parser.add_argument_group(title="Other options")
    filtering = optional.add_mutually_exclusive_group(required=False)
    filtering.add_argument("-f", "--filter", action="store", dest="filter",
                        help="Filter INPUTLIST entries with a wildcard (ex: '*qp28*')")
    filtering.add_argument("-re", "--regexp", action="store", dest="regexp",
                        help="Same as --filter, but use classic regexp instead")

    optional.add_argument("-d", "--directory", action="store", dest="directory",
                        help="Path to directory containing sequences. If INPUTLIST contains relative paths, you must set this variable to the root directory they are relative to.")
    optional.add_argument("--check-yuv", action="store_true", dest="checkYuv", default=False,
                        help="Search for a reference YUV file corresponding to each sequence, and check its consistency while decoding")
    optional.add_argument("--no-nb-frames", action="store_true", dest="noNbFrames", default=False,
                        help="Set to true if you don't want to limit the number of frames to decode. Resulting command line will not contains '-f' option.")
    optional.add_argument("--loops", action="store", default=1, dest="nbLoop", type=int,
                        help="Number of times the input file will be read. Default is 1. Value passed will be used as multiplier on number of frames to decode ('-f' option).")
    optional.add_argument("--verbose", action="store_true", dest="verbose", default=False, help="Verbose mode")

    optional.add_argument("--version", action="version", version= "%(prog)s " + VERSION, help="Print the current version of this script")
    optional.add_argument('-h', "--help", action="help", help="Display this message")

    # parse_known_args() will return a tuple (<known_args> as Namespace, <unknown_args> as List)
    args, additional_args = parser.parse_known_args()

    # Perform some control on arguments passed by user
    if args.directory and not os.path.isdir(args.directory):
        sys.exit("--directory option must contain the path to a valid directory")

    if not os.path.exists(args.inputList):
        sys.exit("Error: file " + args.inputList + " not found!")

    if not which(args.executable):
        sys.exit("Error: executable file " + args.executable + " not found!")

    return (args, additional_args)

def which(program):
    import os
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

def warning(*objs):
    print("WARNING:", *objs, end='\n', file=sys.stderr)

def handler(type, frame):
    global p

    time.sleep(0.5)
    if p and not p.poll():
        # Try to finish the running process
        p.terminate()
        time.sleep(0.5)
        if p.poll():
            print("Process " + str(p.pid) + " have been terminated...")
        else:
            p.kill()
            time.sleep(0.5)
            if p.poll():
                print("Process " + str(p.pid) + " have been killed...")
            else:
                print("Process is still running. You have to kill it by yourself. PID:", str(p.pid))

    if type == signal.SIGINT:
        sys.exit("The test suite has been interrupted !")
    elif type == signal.SIGABRT:
        sys.exit("The test suite has been aborted !")
    else:
        sys.exit("Unknown signal catched: " + str(type))


if __name__ == "__main__":
    # Configure signal handling
    signal.signal(signal.SIGINT, handler)
    signal.signal(signal.SIGABRT, handler)

    p = None
    args, additional_args = configureCommandLine()
    main()
