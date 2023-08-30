#!/usr/bin/env -S -- swipl

:- initialization(main, main).

main(_Argv) :-
    current_prolog_flag(os_argv, [_, Arg0|_]),
    absolute_file_name(Arg0, Abs),
    file_directory_name(Arg0, Dir),
    file_base_name(Arg0, Bin),
    chdir(Dir),
    format("~s~s", ["HELO :: VIA -- ", Bin]),
    nl,
    process_create(path("bat"), ["--", Abs], []).
