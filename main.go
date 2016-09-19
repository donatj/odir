package main

import (
	"flag"
	"fmt"
	"os"
)

func init() {
	flag.Uint("threads", 4, "Number of concurrent downloads")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s <url>:\n", os.Args[0])
		flag.PrintDefaults()
	}

	flag.Parse()

	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(2)
	}
}

func main() {

}
