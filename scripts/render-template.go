package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"
	"time"
)

type module struct {
	Prompt  string `json:"prompt"`
	File    string `json:"file"`
	Command string `json:"command"`
}

func runCmd(name string, args ...string) string {
	out, err := exec.Command(name, args...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func expandHome(path, home string) string {
	if strings.HasPrefix(path, "~/") {
		return home + path[1:]
	}
	return path
}

func osName() string {
	switch runtime.GOOS {
	case "darwin":
		return runCmd("sw_vers", "-productName")
	case "linux":
		data, err := os.ReadFile("/etc/os-release")
		if err != nil {
			return "Linux"
		}
		for _, line := range strings.Split(string(data), "\n") {
			if strings.HasPrefix(line, "NAME=") {
				return strings.Trim(strings.TrimPrefix(line, "NAME="), `"`)
			}
		}
	}
	return runtime.GOOS
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <module-dir>\n", filepath.Base(os.Args[0]))
		os.Exit(1)
	}

	moduleDir := os.Args[1]

	// Find the CUE file
	var cueFile, moduleType string
	for _, t := range []string{"context", "task", "role", "agent"} {
		if _, err := os.Stat(filepath.Join(moduleDir, t+".cue")); err == nil {
			cueFile = t + ".cue"
			moduleType = t
			break
		}
	}
	if cueFile == "" {
		fmt.Fprintf(os.Stderr, "no recognised CUE file found in %s\n", moduleDir)
		os.Exit(1)
	}

	// Run cue export
	cmd := exec.Command("cue", "export", cueFile)
	cmd.Dir = moduleDir
	out, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "cue export failed: %v\n", err)
		os.Exit(1)
	}

	// Parse export JSON
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(out, &raw); err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse export output: %v\n", err)
		os.Exit(1)
	}
	var m module
	if err := json.Unmarshal(raw[moduleType], &m); err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse module fields: %v\n", err)
		os.Exit(1)
	}
	if m.Prompt == "" {
		fmt.Println("(no prompt field)")
		return
	}

	// Gather system values
	u, _ := user.Current()
	home, username := "", ""
	if u != nil {
		home = u.HomeDir
		username = u.Username
	}
	hostname, _ := os.Hostname()
	cwd, _ := os.Getwd()
	filePath := expandHome(m.File, home)

	fileContents := ""
	if filePath != "" {
		if b, err := os.ReadFile(filePath); err == nil {
			fileContents = string(b)
		}
	}

	commandOutput := ""
	if m.Command != "" {
		commandOutput = runCmd("sh", "-c", m.Command)
	}

	data := map[string]string{
		"datetime":       time.Now().Format(time.RFC3339),
		"user":           username,
		"home":           home,
		"hostname":       hostname,
		"os":             runtime.GOOS,
		"os_name":        osName(),
		"shell":          filepath.Base(os.Getenv("SHELL")),
		"cwd":            cwd,
		"git_branch":     runCmd("git", "rev-parse", "--abbrev-ref", "HEAD"),
		"git_root":       runCmd("git", "rev-parse", "--show-toplevel"),
		"git_user":       runCmd("git", "config", "user.name"),
		"git_email":      runCmd("git", "config", "user.email"),
		"file":           filePath,
		"file_contents":  fileContents,
		"command":        m.Command,
		"command_output": commandOutput,
		"instructions":   "",
	}

	tmpl, err := template.New("prompt").Parse(m.Prompt)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to parse template: %v\n", err)
		os.Exit(1)
	}
	if err := tmpl.Execute(os.Stdout, data); err != nil {
		fmt.Fprintf(os.Stderr, "failed to render template: %v\n", err)
		os.Exit(1)
	}
	fmt.Println()
}
