// src/pages/index.tsx
import React, { JSX } from 'react';
import Layout from '@theme/Layout';
import { HeroSection } from '../components/Homepage/HeroSection';
import { FeatureGrid } from '../components/Homepage/FeatureGrid';
import { SocialProof } from '../components/Homepage/SocialProof';
import { QuickStart } from '../components/Homepage/QuickStart';
import { CTASection } from '../components/Homepage/CTASection';
import { Footer } from '../components/Homepage/Footer';

export default function Home(): JSX.Element {
  return (
    <Layout
      title="Homelab - Enterprise-Grade Infrastructure Automation"
      description="Transform your homelab with production-grade infrastructure automation. Built on Kubernetes, GitOps, and modern DevOps practices."
    >
      <HeroSection />
      <FeatureGrid />
      <SocialProof />
      <QuickStart />
      <CTASection />
      <Footer />
    </Layout>
  );
}
