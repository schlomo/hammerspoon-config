function wav_concat --description "Concatenates WAV files using ffmpeg (e.g., wav_concat in1.wav in2.wav out.wav)"
    # Ensure at least 3 arguments are given (2 inputs, 1 output)
    if test (count $argv) -lt 3
        echo "Usage: wav_concat <input1> <input2> ... <output_file>"
        return 1
    end

    # Check for the 'realpath' command, which is needed to resolve file paths
    if not command -v realpath >/dev/null
        echo "Error: 'realpath' command not found. Please install coreutils." >&2
        echo "On macOS with Homebrew, run: brew install coreutils" >&2
        return 1
    end

    # The output file is the very last argument
    set -l output $argv[-1]

    # The input files are all arguments except for the last one
    set -l inputs $argv[1..-2]

    # Use 'realpath' to convert each input file to an absolute path.
    # This ensures ffmpeg can find the files regardless of where the
    # temporary psub list file is located.
    ffmpeg -f concat -safe 0 -i (for f in $inputs; echo "file '$(realpath -- "$f")'"; end | psub) -c copy "$output"
end
