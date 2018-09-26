-module(rebar_compiler_xrl).

-behaviour(rebar_compiler).

-export([metadata/1,
         needed_files/3,
         source_dependencies/3,
         compile/4,
         clean/2]).

metadata(AppInfo) ->
    Dir = rebar_app_info:dir(AppInfo),
    Mappings = [{".erl", filename:join([Dir, "src"])}],
    #{src_dirs => ["src"],
      include_dirs => [],
      src_ext => ".xrl",
      out_mappings => Mappings}.

needed_files(_, FoundFiles, AppInfo) ->
    FirstFiles = [],

    %% Remove first files from found files
    RestFiles = [Source || Source <- FoundFiles, not lists:member(Source, FirstFiles)],

    Opts = rebar_opts:get(rebar_app_info:opts(AppInfo), xrl_opts, []),

    {{FirstFiles, Opts}, {RestFiles, Opts}}.

source_dependencies(_, _, _) ->
    [].

compile(Source, [{_, OutDir}], _, Opts) ->
    BaseName = filename:basename(Source),
    Target = filename:join([OutDir, BaseName]),
    AllOpts = [{parserfile, Target} | Opts],
    AllOpts1 = [{includefile, filename:join(OutDir, I)} || {includefile, I} <- AllOpts,
                                                           filename:pathtype(I) =:= relative],
    case leex:file(Source, AllOpts1 ++ [{return, true}]) of
        {ok, _} ->
            ok;
        {ok, _Mod, Ws} ->
            rebar_compiler:ok_tuple(Source, Ws);
        {error, Es, Ws} ->
            rebar_compiler:error_tuple(Source, Es, Ws, AllOpts1)
    end.

clean(XrlFiles, _AppInfo) ->
    rebar_file_utils:delete_each(
      [rebar_utils:to_list(re:replace(F, "\\.xrl$", ".erl", [unicode]))
       || F <- XrlFiles]).
