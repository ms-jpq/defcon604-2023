#!/usr/bin/env -S -- clojure -M

(import '[java.lang ProcessBuilder ProcessBuilder$Redirect])
(require '[clojure.java.io :as io])

(->> *file*
     io/file .getName
     (str "HELO :: VIA -- ")
     println)

(println "cannot into chdir")

(->
 (ProcessBuilder. ["bat" "--" *file*])
 (.redirectOutput ProcessBuilder$Redirect/INHERIT)
 (.redirectError ProcessBuilder$Redirect/INHERIT)
 .start .waitFor zero? assert)
