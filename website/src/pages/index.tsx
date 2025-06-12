// src/pages/index.tsx
import React, { JSX } from 'react';
import Layout from '@theme/Layout';
import { HeroSection } from '../components/Homepage/HeroSection';
import { TechStack } from '../components/Homepage/TechStack';
import { ProjectStats } from '../components/Homepage/ProjectStats';
import { FeatureGrid } from '../components/Homepage/FeatureGrid';
import { QuickStart } from '../components/Homepage/QuickStart';
import { CTASection } from '../components/Homepage/CTASection';
import { Footer } from '../components/Homepage/Footer';

export default function Home(): JSX.Element {
  return (
    <Layout
      title="An Over-Engineered Homelab Journey"
      description="Exploring enterprise-grade infrastructure automation in a personal homelab. Built with Kubernetes, GitOps, and modern DevOps practices."
    >
      <HeroSection />
      <TechStack />
      <ProjectStats />
      <FeatureGrid />
      <QuickStart />
      <CTASection />
      <Footer />
    </Layout>
  );
}
