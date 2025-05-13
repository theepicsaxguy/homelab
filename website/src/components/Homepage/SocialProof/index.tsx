// src/components/Homepage/SocialProof/index.tsx
import React, { JSX } from 'react';
import styles from './styles.module.css';

interface Testimonial {
  name: string;
  role: string;
  company: string;
  image: string;
  quote: string;
}

const testimonials: Testimonial[] = [
  {
    name: 'John Doe',
    role: 'Senior SRE',
    company: 'Tech Corp',
    image: 'https://github.com/identicon.png',
    quote: 'Finally, a homelab setup that follows real-world best practices. This is exactly what I\'ve been looking for.',
  },
  // Add more testimonials as needed
];

export function SocialProof(): JSX.Element {
  return (
    <section className={styles.socialProof}>
      <div className="container">
        <div className={styles.header}>
          <h2 className={styles.title}>Trusted by DevOps Engineers</h2>
          <p className={styles.subtitle}>
            Join hundreds of developers running production-grade infrastructure at home
          </p>
        </div>
        <div className={styles.testimonials}>
          {testimonials.map((testimonial, idx) => (
            <div key={idx} className={styles.testimonialCard}>
              <div className={styles.testimonialHeader}>
                <img
                  src={testimonial.image}
                  alt={testimonial.name}
                  className={styles.avatar}
                />
                <div className={styles.meta}>
                  <h4 className={styles.name}>{testimonial.name}</h4>
                  <p className={styles.role}>
                    {testimonial.role} @ {testimonial.company}
                  </p>
                </div>
              </div>
              <p className={styles.quote}>{testimonial.quote}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
