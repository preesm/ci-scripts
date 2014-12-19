#!/usr/bin/python
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

import os, sys, re
import argparse
import subprocess, signal

# Configure the command line options
def setupCommandLine():

    global parser
    parser = argparse.ArgumentParser(description='Extract the number of frames and the size of a video sequence, using avconv', version=1.0)
    options = parser.add_argument_group(title="Parameters")
    options.add_argument("-i", "--input", action="store", dest="input",
                        help="The input sequence")
    options.add_argument("-s", "--separator", action="store", dest="separator", default=', ',
                        help='The string used to split results (", " by default)')

# Run avconv to find exact number of fram and size of image of the input sequence
def main():
    args = parser.parse_args()

    if not os.path.exists(args.input):
        sys.exit("Error: file not found " + args.input)
    elif not os.access(args.input, os.R_OK):
        sys.exit("Error: unable to read " + args.input)

    # We will use avconv
    command = ['avconv']
    # Set the input file
    command.extend(['-i', args.input])
    # Do not encode anthing
    command.extend(['-f', 'null', '/dev/null'])

    # Call the command
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # Wait for command end
    proc.wait()
    # Catch the ouput
    avconvOuput = proc.stdout.read()

    # Get the video size
    sizeResult = re.search("\s+Stream #0.0.+\s([0-9]+x[0-9]+)", avconvOuput, re.MULTILINE)
    if sizeResult:
        videoSize = sizeResult.group(1)
    else:
        videoSize = ''

    # Get the decoded frame number
    framesResult = re.search("frame=\s+([0-9]+) fps", avconvOuput, re.MULTILINE)
    if framesResult:
        nbFrames = framesResult.group(1)
    else:
        nbFrames = '-1'

    # Compute the result list
    results = [args.input, nbFrames, videoSize]

    # Print the result
    print args.separator.join(results)
    sys.exit(0)

def handler(type, frame):
    if type == signal.SIGINT:
        sys.exit("The script has been interrupted !")
    elif type == signal.SIGABRT:
        sys.exit("The script has been aborted !")
    else:
        sys.exit("Unknown signal catched: " + str(type))

if __name__ == "__main__":
    signal.signal(signal.SIGINT, handler)
    signal.signal(signal.SIGABRT, handler)

    setupCommandLine()
    main()