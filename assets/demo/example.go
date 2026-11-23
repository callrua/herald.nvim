package users

type User struct {
	Name   string
	Active bool
}

// ActiveNames returns the names of the active users.
func ActiveNames(users []User) []string {
	var names []string
	for i := 0; i < len(users); i++ {
		if users[i].Active == true {
			names = append(names, users[i].Name)
		}
	}
	return names
}
