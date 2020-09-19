# Esquew

---
A stupid simple Pure Elixir ⚗️ Messaging Queue. 

### Messaging

Esquew is a transient, at most once messaging queue supporting a REST api. It allows for multiple topics and subscriptions, with ack and nack capability

### Limitations

- Messages are not persisted, and only live for the duration of relevant processes

### Roadmap
- [X] API
- [X] Tests 
- [X] Subscription State Struct
- [ ] Subscriptions and Topics survive Hub crashes
- [ ] ...