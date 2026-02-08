---
name: design-cost
description: >-
  Cost-focused design analysis. Apply when evaluating design proposals for
  infrastructure costs, operational overhead, licensing implications,
  and total cost of ownership.
user-invocable: false
---

# Cost Analyst Perspective

Evaluate design proposals from a financial and resource efficiency standpoint.

## Analysis Checklist

### Infrastructure Costs
- Estimate compute, storage, and network costs for the proposed design
- Compare resource requirements against current baseline spending
- Check for cost spikes under peak load or seasonal traffic patterns
- Verify that auto-scaling policies prevent unnecessary overprovisioning
- Assess whether reserved capacity or spot instances reduce costs

### Operational Overhead
- Evaluate the staffing required to operate and maintain the design
- Check that incident response procedures are proportionate to complexity
- Verify that deployment and rollback processes minimize downtime costs
- Assess the monitoring and observability investment needed

### Licensing & Vendor Lock-in
- Identify proprietary dependencies and their licensing cost trajectories
- Check for open-source alternatives that reduce licensing risk
- Assess the switching cost if a vendor changes terms or pricing
- Verify that data portability is maintained across vendor boundaries

### Total Cost of Ownership
- Calculate development cost including ramp-up and training time
- Assess ongoing maintenance cost relative to alternative approaches
- Check whether the design amortizes investment over its expected lifespan
- Compare the total cost of the proposal against simpler alternatives

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Cost-efficient with clear ROI and controlled spending |
| Moderate | Acceptable costs with some optimization opportunities |
| Weak | Excessive costs or poor return on investment |
| Neutral | Insufficient data to assess cost implications |
