# CD Config Examples

This repository provides a set of guidelines and examples that demonstrate how to implement Continuous Delivery (CD) using CircleCI.

## Introduction

Continuous Delivery (CD) is a software development practice where code changes are automatically built, tested, and prepared for a release to production. It's an extension of Continuous Integration (CI), taking the concept a step further by deploying all code changes after the build stage. At the same time, it monitors to ensure that the newly released version is in a stable state and ready to take on more responsibility or be promoted to other environments. This practice ensures that you can release a new version of your software quickly and sustainably, without dedicating resources to oversee the deployment of your software.

This project is designed to help you implement robust Continuous Delivery pipelines using CircleCI. It contains practical examples and guidelines, providing a hands-on approach to setting up your own CD pipelines.

## Examples

* [Kubernetes Release Agent Onboarding](./guidelines/k8s-release-agent-onboarding.md): Dive into the process of installing and utilizing the CircleCI Kubernetes Release Agent. This example guides you through both local installation for rapid testing and cluster-based installation for real-time workload monitoring with CircleCI.

## Note

As time progresses, more guidelines will be added to this repository, and existing ones will be updated to reflect the evolution of CircleCI's Continuous Delivery offerings. Stay tuned for these enhancements!
