# Epytype Operations

Infrastructure-as-code for epytype.org services.

## Prerequisites
The `kpxc/` directory must be pulled as a subdirectory of `ops/`:
```
<epytype.org home>/ops/kpxc/epytype_ops.kdbx
```

## Load Credentials
From the `ops/` directory:

```bash
cd <epytype.org home>/ops
source ./bin/loadenv.sh
```

This loads required credientals into your environment.
