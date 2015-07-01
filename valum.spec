Name:       valum
Version:    0.2.0
Release:    1%{?dist}
Summary:    Valum is a web micro-framework written in Vala

Group:      Development/Libraries
License:    LGPL
URL:        https://github.com/valum-framework/valum
Source0:    %{name}-%{version}-alpha.tar.bz2

BuildRequires: python, vala

%description
Valum is a web micro-framework able to create highly scalable expressive web
applications or services by taking advantage of machine code execution and
asynchronous I/O.

%package devel
Summary:    Build files for Valum

%description devel
Provides build files including C header, Vala bindings and GIR introspection
meta-data.

%prep
%setup -q -n %{name}-%{version}-alpha

%build
./waf configure --prefix=%{_prefix}
./waf build

%install
./waf install --destdir=%{buildroot}

%check
LD_LIBRARY_PATH=%{buildroot}%{_libdir} ./build/tests/tests

%files
%doc README.md LGPL
%{_libdir}/*

%files devel
%{_datadir}/*
%{_includedir}/*

