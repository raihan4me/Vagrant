#!/usr/bin/env bash
LAB="$HOME/vagrant-lab"
PASS=0; FAIL=0
check() {
  local desc="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "PASS  $desc"; PASS=$((PASS+1))
  else
    echo "FAIL  $desc"; FAIL=$((FAIL+1))
  fi
}
state() {  # state <project> <machine>
  (cd "$LAB/$1" && vagrant status "$2" --machine-readable 2>/dev/null | awk -F, '$3=="state"{print $4}')
}

echo "== Setup"
check "Vagrant 2.4.x installed"            'vagrant --version | grep -q "Vagrant 2.4."'
check "Docker usable without sudo"         'docker info'
check "Ansible in venv"                    '"$LAB/.venv/bin/ansible-playbook" --version'

echo "== Task 1"
check "Base image 1.0.0 built"             'docker image inspect devops-lab/vagrant-ubuntu:1.0.0'
check "First machine cleaned up"           'test "$(state first default)" = "not_created"'

echo "== Task 2 / Task 6 boxes"
check "Catalog lists 1.0.0 and 1.1.0"      'jq -r "[.versions[].version] | join(\",\")" "$LAB/boxes/catalog.json" | grep -qx 1.0.0,1.1.0'
check "Box 1.0.0 installed"                'vagrant box list | grep "devops/ubuntu2404" | grep -q "1.0.0"'
check "Box 1.1.0 installed"                'vagrant box list | grep "devops/ubuntu2404" | grep -q "1.1.0"'

echo "== Task 3"
check "web machine running"                'test "$(state web default)" = "running"'
check "web /healthz returns ok"            'curl -fs http://127.0.0.1:8080/healthz | grep -qx ok'
check "web meta shows provisioner env"     'curl -fs http://127.0.0.1:8080/meta/info.txt | grep -q "owner=Ops Team"'

echo "== Task 4 / Task 5"
for m in app1 app2 lb; do
  check "cluster $m running"               "test \"\$(state cluster $m)\" = running"
done
check "lb balances across 2 backends"      'for i in 1 2 3 4; do curl -fs http://127.0.0.1:8090/; done | grep -o app[12] | sort -u | wc -l | grep -qx 2'
check "apps deployed by Ansible (v2.0)"    'curl -fs http://127.0.0.1:8090/ | grep -q 2.0'
check "per-host color variables applied"   'curl -fs http://192.168.60.12:5000/ | grep -q green'

echo "== Task 6"
check "fleet tools running"                'test "$(state fleet tools)" = "running"'
check "fleet legacy running"               'test "$(state fleet legacy)" = "running"'
check "fleet scratch not autostarted"      'test "$(state fleet scratch)" = "not_created"'
check "tools runs box 1.1.0"               '(cd "$LAB/fleet" && vagrant ssh tools -c "cat /etc/box-release") | grep -q "1.1.0"'
check "legacy runs box 1.0.0"              '(cd "$LAB/fleet" && vagrant ssh legacy -c "cat /etc/box-release") | grep -q "1.0.0"'
check "triggers wrote events log"          'grep -q " up tools$" "$LAB/fleet/fleet-events.log"'

echo "== Task 7"
check "troubleshoot Vagrantfile valid"     '(cd "$LAB/troubleshoot" && vagrant validate)'
check "troubleshoot machine running"       'test "$(state troubleshoot default)" = "running"'
check "troubleshoot serves content"        'curl -fs http://127.0.0.1:8095/ | grep -q "tshoot ok"'
check "sshd restored as container CMD"     'docker inspect -f "{{.Config.Cmd}}" tshoot | grep -q sshd'

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
