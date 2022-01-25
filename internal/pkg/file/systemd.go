package file

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/andrewmarklloyd/pi-app-updater/internal/pkg/config"
)

const (
	systemDPath = "/etc/systemd/system"
)

type SystemdTool struct {
	UnitPath    string
	UnitName    string
	UpdaterPath string
}

func NewSystemdTool(testMode bool, cfg config.Config) SystemdTool {
	s := SystemdTool{}
	if testMode {
		s.UnitPath = fmt.Sprintf("/tmp/%s/%s.service", cfg.PackageName, cfg.PackageName)
	} else {
		s.UnitPath = fmt.Sprintf("%s/%s.service", systemDPath, cfg.PackageName)
	}
	s.UnitName = fmt.Sprintf("%s.service", cfg.PackageName)
	return s
}

func (s SystemdTool) FindApiKeyFromSystemd() (string, error) {
	f, err := os.Open(s.UnitPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	var keyLineString string
	scanner := bufio.NewScanner(f)
	line := 1
	for scanner.Scan() {
		if strings.Contains(scanner.Text(), "HEROKU_API_KEY") {
			keyLineString = scanner.Text()
			break
		}
		line++
	}

	if err := scanner.Err(); err != nil {
		return "", err
	}

	split := strings.Split(keyLineString, "=")
	if len(split) != 3 {
		return "", fmt.Errorf("expected systemd file heroku api key line to have length 3")
	}

	return split[2], nil
}

func (s SystemdTool) SetupSystemdUnits() error {
	_, err := exec.Command("systemctl", "daemon-reload").Output()
	if err != nil {
		return fmt.Errorf("%s", err)
	}

	_, err = exec.Command("systemctl", "start", s.UnitName).Output()
	if err != nil {
		return fmt.Errorf("starting %s systemd unit: %s", s.UnitName, err)
	}

	_, err = exec.Command("systemctl", "start", "pi-app-updater").Output()
	if err != nil {
		return fmt.Errorf("starting pi-app-updater systemd unit: %s", err)
	}

	return nil
}

func (s SystemdTool) StopSystemdUnit() error {
	_, err := exec.Command("systemctl", "stop", s.UnitName).Output()
	if err != nil {
		return fmt.Errorf("%s", err)
	}
	return nil
}

func (s SystemdTool) Uninstall() error {
	if err := s.StopSystemdUnit(); err != nil {
		return err
	}

	if _, err := exec.Command("systemctl", "stop", "pi-app-updater").Output(); err != nil {
		return fmt.Errorf("stopping pi-app-updater systemd unit: %s", err)
	}

	if _, err := exec.Command("systemctl", "daemon-reload").Output(); err != nil {
		return fmt.Errorf("running daemon-reload: %s", err)
	}

	if err := os.Remove(s.UnitPath); err != nil {
		return err
	}

	if err := os.Remove(s.UpdaterPath); err != nil {
		return err
	}

	return nil
}
