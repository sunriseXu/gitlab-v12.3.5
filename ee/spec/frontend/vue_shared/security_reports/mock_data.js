export const baseIssues = [
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 21,
        end: 21,
      },
    },
    fingerprint: 'ca2354534dee94ae60ba2f54e3857c50e5',
  },
];

export const sastParsedIssues = [
  {
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    line: 12,
    priority: 'High',
    urlPath: 'foo/Gemfile.lock',
  },
];

export const sastIssues = [
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Arbitrary file existence disclosure in Action Pack',
    cve: 'CVE-2014-7829',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2014-7829',
        value: 'CVE-2014-7829',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-7829',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-0752',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0752',
        value: 'CVE-2016-0752',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0752',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    cve: 'CVE-2016-0751',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0751',
        value: 'CVE-2016-0751',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0751',
      },
    ],
  },
];

export const sastIssuesMajor2 = {
  version: '2.0',
  vulnerabilities: sastIssues,
};

export const oldSastIssues = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
  },
];

export const sastIssuesBase = [
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Test Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-9999',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-9999',
        value: 'CVE-2016-9999',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-9999',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-0752',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0752',
        value: 'CVE-2016-0752',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0752',
      },
    ],
  },
];

export const parsedSastIssuesStore = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    cve: 'CVE-2014-7829',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5-10',
    category: 'sast',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2014-7829',
        value: 'CVE-2014-7829',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-7829',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-0752',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'sast',
    project_fingerprint: 'a6b61a2eba59071178d5899b26dd699fb880de1e',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0752',
        value: 'CVE-2016-0752',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0752',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    cve: 'CVE-2016-0751',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'sast',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0751',
        value: 'CVE-2016-0751',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0751',
      },
    ],
  },
];

export const parsedSastIssuesHead = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    cve: 'CVE-2014-7829',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5-10',
    category: 'sast',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2014-7829',
        value: 'CVE-2014-7829',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-7829',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    cve: 'CVE-2016-0751',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'sast',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0751',
        value: 'CVE-2016-0751',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0751',
      },
    ],
  },
];

export const parsedSastBaseStore = [
  {
    title: 'Test Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-9999',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5-10',
    category: 'sast',
    project_fingerprint: '3f5608c99f0c7442ba59bc6c0c1864d0000f8e1a',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-9999',
        value: 'CVE-2016-9999',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-9999',
      },
    ],
  },
];

export const dependencyScanningIssuesOld = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const dependencyScanningIssues = [
  {
    category: 'dependency_scanning',
    message: 'ruby-ffi DDL loading issue on Windows OS',
    cve: 'sast-sample-rails/Gemfile.lock:ffi:cve:CVE-2018-1000201',
    severity: 'High',
    solution: 'upgrade to \u003e= 1.9.24',
    scanner: {
      id: 'bundler_audit',
      name: 'bundler-audit',
    },
    location: {
      file: 'sast-sample-rails/Gemfile.lock',
      dependency: {
        package: {
          name: 'ffi',
        },
        version: '1.9.18',
      },
    },
    identifiers: [
      {
        type: 'cve',
        name: 'CVE-2018-1000201',
        value: 'CVE-2018-1000201',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-1000201',
      },
    ],
    links: [
      {
        url: 'https://github.com/ffi/ffi/releases/tag/1.9.24',
      },
    ],
  },
  {
    category: 'dependency_scanning',
    message: 'XSS vulnerability in rails-html-sanitizer',
    cve: 'sast-sample-rails/Gemfile.lock:rails-html-sanitizer:cve:CVE-2018-3741',
    severity: 'Unknown',
    solution: 'upgrade to \u003e= 1.0.4',
    scanner: {
      id: 'bundler_audit',
      name: 'bundler-audit',
    },
    location: {
      file: 'sast-sample-rails/Gemfile.lock',
      dependency: {
        package: {
          name: 'rails-html-sanitizer',
        },
        version: '1.0.3',
      },
    },
    identifiers: [
      {
        type: 'cve',
        name: 'CVE-2018-3741',
        value: 'CVE-2018-3741',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3741',
      },
    ],
    links: [
      {
        url: 'https://groups.google.com/d/msg/rubyonrails-security/tP7W3kLc5u4/uDy2Br7xBgAJ',
      },
    ],
  },
  {
    category: 'dependency_scanning',
    message: 'Vulnerability in ansi2html',
    cve: ':ansi2html:npm:51',
    severity: 'High',
    scanner: {
      id: 'retire.js',
      name: 'Retire.js',
    },
    location: {
      dependency: {
        package: {
          name: 'ansi2html',
        },
        version: '0.0.1',
      },
    },
    identifiers: [
      {
        type: 'npm',
        name: 'NPM-51',
        value: '51',
        url: 'https://www.npmjs.com/advisories/51',
      },
    ],
    links: [
      {
        url: 'https://nodesecurity.io/advisories/51',
      },
    ],
  },
];

export const dependencyScanningIssuesMajor2 = {
  version: '2.0',
  vulnerabilities: dependencyScanningIssues,
  remediations: [
    {
      fixes: [{ cve: dependencyScanningIssues[0].cve }],
      summary: 'Fixes the first dependency Scanning issue',
    },
  ],
};

export const dependencyScanningIssuesBase = [
  {
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const parsedDependencyScanningIssuesStore = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5',
    category: 'dependency_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: 'a6b61a2eba59071178d5899b26dd699fb880de1e',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
  },
];

export const parsedDependencyScanningIssuesHead = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5',
    category: 'dependency_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
  },
];

export const parsedDependencyScanningBaseStore = [
  {
    title: 'Test Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '3f5608c99f0c7442ba59bc6c0c1864d0000f8e1a',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
  },
];

export const parsedSastContainerBaseStore = [
  {
    category: 'container_scanning',
    message: 'CVE-2014-8130',
    description: 'debian:8 is affected by CVE-2014-8130.',
    cve: 'CVE-2014-8130',
    severity: 'Low',
    confidence: 'Medium',
    location: { image: 'registry.example.com/example/master:1234', operating_system: 'debian:8' },
    scanner: { id: 'clair', name: 'Clair' },
    identifiers: [
      {
        name: 'CVE-2014-8130',
        type: 'CVE',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-8130',
        value: 'CVE-2014-8130',
      },
    ],
    project_fingerprint: '20a19f706d82cec1c04d1c9a8858e89b142d602f',
    title: 'CVE-2014-8130',
    vulnerability: 'CVE-2014-8130',
  },
];

export const allIssuesParsed = [
  {
    title: 'Possible Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
];

export const dockerReport = {
  image: 'registry.example.com/example/master:1234',
  unapproved: ['CVE-2017-12944', 'CVE-2017-16232'],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
  ],
};

export const dockerBaseReport = {
  image: 'registry.example.com/example/master:1234',
  unapproved: ['CVE-2017-12944', 'CVE-2014-8130'],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
  ],
};

export const dockerNewIssues = [
  {
    category: 'container_scanning',
    message: 'CVE-2017-16232',
    description: 'debian:8 is affected by CVE-2017-16232.',
    cve: 'CVE-2017-16232',
    severity: 'Low',
    confidence: 'Medium',
    location: { image: 'registry.example.com/example/master:1234', operating_system: 'debian:8' },
    scanner: { id: 'clair', name: 'Clair' },
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2017-16232',
        value: 'CVE-2017-16232',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
      },
    ],
    project_fingerprint: '4e010f6d292364a42c6bb05dbd2cc788c2e5e408',
    title: 'CVE-2017-16232',
    vulnerability: 'CVE-2017-16232',
  },
];

export const dockerOnlyHeadParsed = [
  {
    category: 'container_scanning',
    message: 'CVE-2017-12944',
    description: 'debian:8 is affected by CVE-2017-12944.',
    cve: 'CVE-2017-12944',
    severity: 'Medium',
    confidence: 'Medium',
    location: { image: 'registry.example.com/example/master:1234', operating_system: 'debian:8' },
    scanner: { id: 'clair', name: 'Clair' },
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2017-12944',
        value: 'CVE-2017-12944',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
      },
    ],
    project_fingerprint: '0693a82ef93c5e9d98c23a35ddcd8ed2cbd047d9',
    title: 'CVE-2017-12944',
    vulnerability: 'CVE-2017-12944',
  },
  {
    category: 'container_scanning',
    message: 'CVE-2017-16232',
    description: 'debian:8 is affected by CVE-2017-16232.',
    cve: 'CVE-2017-16232',
    severity: 'Low',
    confidence: 'Medium',
    location: { image: 'registry.example.com/example/master:1234', operating_system: 'debian:8' },
    scanner: { id: 'clair', name: 'Clair' },
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2017-16232',
        value: 'CVE-2017-16232',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
      },
    ],
    project_fingerprint: '4e010f6d292364a42c6bb05dbd2cc788c2e5e408',
    title: 'CVE-2017-16232',
    vulnerability: 'CVE-2017-16232',
  },
];

export const dockerReportParsed = {
  unapproved: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
  ],
  approved: [
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-v',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
};

export const multiSitesDast = {
  site: [
    {
      '@port': '8080',
      '@host': 'goat',
      '@name': 'http://goat:8080',
      alerts: [
        {
          name: 'Absence of Anti-CSRF Tokens',
          riskcode: '1',
          riskdesc: 'Low (Medium)',
          cweid: '3',
          desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
          pluginid: '123',
          solution: '<p>Update to latest</p>',
          instances: [
            {
              uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
              method: 'GET',
              evidence:
                "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
            },
            {
              uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
              method: 'GET',
              evidence:
                "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
            },
          ],
        },
        {
          alert: 'X-Content-Type-Options Header Missing',
          name: 'X-Content-Type-Options Header Missing',
          riskdesc: 'Low (Medium)',
          cweid: '4',
          desc:
            '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
          pluginid: '3456',
          solution: '<p>Update to latest</p>',
          instances: [
            {
              uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
              method: 'GET',
              param: 'X-Content-Type-Options',
            },
          ],
        },
      ],
      '@ssl': 'false',
    },
    {
      '@port': '8081',
      '@host': 'nginx',
      '@name': 'http://nginx:8081',
      alerts: [
        {
          alert: 'X-Content-Type-Options Header Missing',
          name: 'X-Content-Type-Options Header Missing',
          riskdesc: 'Low (Medium)',
          cweid: '4',
          desc:
            '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
          pluginid: '3456',
          solution: '<p>Update to latest</p>',
          instances: [
            {
              uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
              method: 'GET',
              param: 'X-Content-Type-Options',
            },
          ],
        },
      ],
      '@ssl': 'false',
    },
  ],
};

export const dast = {
  site: {
    alerts: [
      {
        name: 'Absence of Anti-CSRF Tokens',
        riskcode: '1',
        riskdesc: 'Low (Medium)',
        cweid: '3',
        desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
        pluginid: '123',
        solution: '<p>Update to latest</p>',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
            method: 'GET',
            evidence:
              "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
          },
          {
            uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
            method: 'GET',
            evidence:
              "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
          },
        ],
      },
      {
        alert: 'X-Content-Type-Options Header Missing',
        name: 'X-Content-Type-Options Header Missing',
        riskdesc: 'Low (Medium)',
        cweid: '4',
        desc:
          '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
        pluginid: '3456',
        solution: '<p>Update to latest</p>',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
            method: 'GET',
            param: 'X-Content-Type-Options',
          },
        ],
      },
    ],
  },
};

export const dastBase = {
  site: {
    alerts: [
      {
        name: 'Absence of Anti-CSRF Tokens',
        riskcode: '1',
        riskdesc: 'Low (Medium)',
        cweid: '03',
        desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
        pluginid: '123',
        solution: '<p>Update to latest</p>',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
            method: 'GET',
            evidence:
              "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
          },
          {
            uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
            method: 'GET',
            evidence:
              "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
          },
        ],
      },
    ],
  },
};

export const parsedMultiSitesDast = [
  {
    category: 'dast',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
    name: 'Absence of Anti-CSRF Tokens',
    title: 'Absence of Anti-CSRF Tokens',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
    severity: 'Low',
    confidence: 'Medium',
    cweid: '3',
    desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
    pluginid: '123',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-3',
        value: '3',
        url: 'https://cwe.mitre.org/data/definitions/3.html',
      },
    ],
    instances: [
      {
        uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
      {
        uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
    ],
    solution: ' Update to latest ',
    description: ' No Anti-CSRF tokens were found in a HTML submission form. ',
  },
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'Low',
    confidence: 'Medium',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'Low',
    confidence: 'Medium',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
];

export const parsedDast = [
  {
    category: 'dast',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
    name: 'Absence of Anti-CSRF Tokens',
    title: 'Absence of Anti-CSRF Tokens',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
    severity: 'Low',
    confidence: 'Medium',
    cweid: '3',
    desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
    pluginid: '123',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-3',
        value: '3',
        url: 'https://cwe.mitre.org/data/definitions/3.html',
      },
    ],
    instances: [
      {
        uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
      {
        uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
    ],
    solution: ' Update to latest ',
    description: ' No Anti-CSRF tokens were found in a HTML submission form. ',
  },
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'Low',
    confidence: 'Medium',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
];

export const parsedDastNewIssues = [
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'Low',
    confidence: 'Medium',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
];

/**
 * SAST report API response for no added & fixed issues but with security issues
 */
export const sastHeadAllIssues = [
  {
    cve: 'CVE-2014-7829',
    tool: 'retire',
    url: 'https://github.com/jquery/jquery/issues/2432',
    file: '/builds/gonzoyumo/test-package-lock/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
    message: '3rd party CORS request may execute',
  },
  {
    cve: 'CVE-2014-7828',
    tool: 'retire',
    url: 'https://bugs.jquery.com/ticket/11974',
    file: '/builds/gonzoyumo/test-package-lock/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
    message: 'parseHTML() executes scripts in event handlers',
  },
  {
    cve: 'CVE-2014-7827',
    tool: 'retire',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
    message: 'growl_command-injection',
  },
  {
    cve: 'CVE-2014-7826',
    tool: 'retire',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
    message: 'growl_command-injection',
  },
];

export const sastBaseAllIssues = [
  {
    cve: 'CVE-2014-7829',
    tool: 'gemnasium',
    message: 'Command Injection for growl',
    url: 'https://github.com/tj/node-growl/pull/61',
    file: 'package-lock.json',
  },
  {
    cve: 'CVE-2014-7828',
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for tough-cookie',
    url: 'https://github.com/salesforce/tough-cookie/issues/92',
    file: 'package-lock.json',
  },
  {
    cve: 'CVE-2014-7827',
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for string',
    url: 'https://github.com/jprichardson/string.js/issues/212',
    file: 'package-lock.json',
  },
  {
    cve: 'CVE-2014-7826',
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for debug',
    url: 'https://nodesecurity.io/advisories/534',
    file: 'package-lock.json',
  },
  {
    cve: 'CVE-2014-7825',
    tool: 'retire',
    message: '3rd party CORS request may execute',
    url: 'https://github.com/jquery/jquery/issues/2432',
    file: '/code/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
  },
  {
    cve: 'CVE-2014-7824',
    tool: 'retire',
    message: 'parseHTML() executes scripts in event handlers',
    url: 'https://bugs.jquery.com/ticket/11974',
    file: '/code/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
  },
  {
    cve: 'CVE-2014-7823',
    tool: 'retire',
    message: 'growl_command-injection',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
  },
  {
    cve: 'CVE-2014-7822',
    tool: 'retire',
    message: 'growl_command-injection',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
  },
];

export const sastFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'sast',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'sast',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dependencyScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dastFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
];

export const containerScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: '0693a82ef93c5e9d98c23a35ddcd8ed2cbd047d9',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: '0693a82ef93c5e9d98c23a35ddcd8ed2cbd047d9',
  },
];
