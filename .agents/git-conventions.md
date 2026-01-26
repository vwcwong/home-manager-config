# Git Conventions

This document describes the git commit message conventions used in this repository.

## Commit Message Format

Commit messages follow the conventional commits format:

```
type(scope): Description
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `ai`: AI-related changes

### Scopes

Scopes indicate the area of the codebase affected:

- `ai`: AI-related tools
- `keybinds`: Keyboard bindings configuration
- `hm`: Home Manager configuration
- `k8s`: Kubernetes-related tools
- `tf`: Terraform-related tools
- `rust`: Rust-related tools
- `aws`: AWS-related tools
- `docker`: Docker-related tools
- `zsh`: Zsh shell configuration
- `git`: Git configuration
- `readme`: README documentation

#### Multiple Scopes

Changes can affect multiple scopes. When this happens:
- Separate scopes with commas
- Organize scopes alphabetically
- If there are more than 3 scopes, consider using a global scope instead

Example: `feat(aws, docker, k8s): Add cloud infrastructure tools`

### Description

- Capitalize the first letter
- Use imperative mood ("Add" not "Added" or "Adds")
- No period at the end
- Keep it concise and descriptive

## Examples

```
feat(keybinds): Bind CTRL+Left/Right for word navigation
feat(hm): Allow unfree packages on macOS
feat(k8s): Add Kustomize
feat(tf): Add Terraform CLI
feat(rust): Add Rust tools
feat(aws): Add AWS CLI
feat(k8s): Add Kubernetes tools
feat(docker): Add Docker and Docker Compose
docs(readme): Specify clone location
docs(readme): Fix repository path
feat(zsh): Set up p10k and common plugins
feat(git): Add Git configuration
docs(readme): Add installation instructions
feat(hm): Add base configuration
fix(hm): Resolve package installation error
ai(hm): Add AI agent documentation
feat(ai): Add Cursor IDE
feat(aws,docker,k8s): Add cloud infrastructure tools
```

