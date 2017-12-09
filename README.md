# Abaco CLI

Command line interface for working with the Abaco (Actor Based Containers) API

Dependent upon [jq](https://stedolan.github.io/jq/), getopts, and the [Agave CLI](https://bitbucket.org/agaveapi/cli)

## Installation

```
$ git clone https://github.com/johnfonner/abaco-cli.git
```

## Set up

Enable bash completion.
```
$ source abaco-completion.sh
```

Pull and cache a valid access token using the Agave CLI.
```
$ auth-tokens-refresh -S
```

## Usage

There are seven possible commands. They can be seen using the tab completion set up above; simply set up the `abaco` command and hit the tab key twice.
```
$ ./abaco 
create    delete    executions    list
logs      submit    workers
```

Each command has a help message, which can be viewed with the `-h` flag. The `abaco` command also has a help message that overviews the function of each command, as shown below.
```
$ ./abaco -h

./abaco [COMMAND] [OPTION]...

Set of commands for interacting with abaco API. Options vary by 
command; use -h flag after command to view.

Commands:
  list, ls, actors, images      list actors
  create, make, register        create new actor
  delete, remove, rm            remove actor
  workers, worker               view and add workers
  submit, run                   run actor
  executions                    view actor executions
  logs                          view execution logs
```

## Tutorial

Here, we'll outline the seven steps in the Abaco workflow using the commands in this cli. We use a [sample container](https://hub.docker.com/r/jturcino/abaco-cli-trial/) called `jturcino/abaco-cli-trial:latest`. When run, it simply prints the actor's environmental and context variables generated via [agavepy](https://github.com/TACC/agavepy).

1. **Create the actor** with `abaco create` using a Docker container. The command outputs the actor's name and ID.
```
$ ./abaco create -n tutorial-example jturcino/abaco-gen-trial:0.0.1
tutorial-example  Wyx0x356VoNyN
```

2. **Check actor's status** with `abaco list`. The command outputs all actor names, IDs, and statuses. To view a detailed JSON description, use the `-v` flag and append the actor ID to the end of the command.
```
./abaco list 
tutorial-example    Wyx0x356VoNyN    READY
```

3. **Run the actor** with `abaco submit` once the status is `READY`. Pass information to the actor with the `-m` flag as a string or as JSON (here using JSON); this information will be available as a dictionary under `message_dict`. Be sure to append the actor ID to the end of the command. The command outputs the execution ID and `MSG` input.
```
$ msg='{"key1":"value1", "key2":"value2"}'
$ ./abaco submit -m $msg Wyx0x356VoNyN
QZ10OLzA3XDW6
{
  "key1": "value1",
  "key2": "value2"
}
```

4. **Check job status** with `abaco executions`. Providing only the actor ID lists all execution IDs associated with that actor. Providing the execution ID (output from `abaco-submit`) with the `-e` flag returns the job's status and worker ID.
```
$ ./abaco executions -e QZ10OLzA3XDW6 Wyx0x356VoNyN
vaO8x0D8q16Y5  COMPLETE
```

5. **(Optional) View worker description** with `abaco workers`. Output is a list of associated worker IDs and their statuses. A longer JSON description is returned if a worker ID is provided with the `-w` flag.
```
$ ./abaco workers Wyx0x356VoNyN
vaO8x0D8q16Y5  READY
```

6. **Examine job log** with `abaco logs` by providing both the actor ID and execution ID (`-e` flag). For our sample container, we can see the full agavepy context, the JSON message we passed to the actor, and the full environment.
```
$ ./abaco logs -e QZ10OLzA3XDW6 Wyx0x356VoNyN
Logs for execution QZ10OLzA3XDW6:
FULL CONTEXT:
{
  "username": "jturcino", 
  "_abaco_jwt_header_name": "X-Jwt-Assertion-Sd2E", 
  "_abaco_actor_id": "Wyx0x356VoNyN", 
  "raw_message": "{'json': 'msg'}", 
  "actor_dbid": "SD2E_Wyx0x356VoNyN", 
  "_abaco_actor_state": "{}", 
  "content_type": null, 
  "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 
  "MSG": "{'key1':'value1', 'key2':'value2'}", 
  "_abaco_api_server": "https://api.sd2e.org", 
  "_abaco_Content_Type": "application/json", 
  "execution_id": "QZ10OLzA3XDW6", 
  "_abaco_access_token": "", 
  "message_dict": {
    "key1": "value1",
    "key2": "value2"
  }, 
  "_abaco_actor_dbid": "SD2E_Wyx0x356VoNyN", 
  "HOSTNAME": "", 
  "_abaco_execution_id": "QZ10OLzA3XDW6", 
  "state": "{}", 
  "_abaco_username": "jturcino", 
  "actor_id": "Wyx0x356VoNyN", 
  "HOME": "/root"
}

MESSAGE:
{
    "key1": "value1",
    "key2": "value2"
}

FULL ENVIRONMENT:
{
  "_abaco_actor_state": "{}", 
  "_abaco_access_token": "", 
  "_abaco_actor_dbid": "SD2E_Wyx0x356VoNyN", 
  "HOSTNAME": "", 
  "_abaco_execution_id": "QZ10OLzA3XDW6", 
  "_abaco_Content_Type": "application/json", 
  "_abaco_username": "jturcino", 
  "_abaco_actor_id": "Wyx0x356VoNyN", 
  "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 
  "MSG": "{'key1':'value1', 'key2':'value2'}", 
  "_abaco_api_server": "https://api.sd2e.org", 
  "HOME": "/root", 
  "_abaco_jwt_header_name": "X-Jwt-Assertion-Sd2E"
}
```

7. **Delete the actor** with `abaco delete` by providing the actor ID.
```
$ ./abaco delete Wyx0x356VoNyN
Actor deleted successfully.
```