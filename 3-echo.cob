#!/usr/bin/env -S -- bash -Eeuo pipefail
       *> . || cobc -Wall -x "$0" -o "${T:="$(mktemp)"}" && exec -a "$0" -- "$T" "$@"
       >>SOURCE FORMAT FREE

       IDENTIFICATION DIVISION.
       PROGRAM-ID. HOLA.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 PTR POINTER.
       01 ENV-NAME PIC XXXX VALUE "PATH".
       01 ENV-LEN PIC 9(8) BINARY VALUE 0.

       LINKAGE SECTION.
       01 ENV PIC X(9999).

       PROCEDURE DIVISION.
           SET PTR TO ADDRESS OF ENV-NAME.
           CALL "getenv" USING BY VALUE PTR RETURNING PTR
           SET ADDRESS OF ENV TO PTR
           INSPECT ENV TALLYING ENV-LEN
             FOR CHARACTERS BEFORE INITIAL X"00"
           DISPLAY ENV(1:ENV-LEN).
